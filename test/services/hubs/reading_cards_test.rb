require "test_helper"

class Hubs::ReadingCardsTest < ActiveSupport::TestCase
  setup do
    @person = people(:pili)
    @suggestions = quiz_suggestions(3)
  end

  test "makes one chapter card per study and resolves its localized title" do
    first = @suggestions.first

    cards = Hubs::ReadingCards.call(person: @person, locale: :fr, suggestions: [ first, first ])

    assert_equal 1, cards.size
    card = cards.first
    assert_equal first.study, card.study
    assert_equal first.cite, card.cite
    chapter = Scriptures::Reference.from_study(study: first.study, locale: :fr, verse: 1)
    assert_equal "#{chapter.book_label} #{chapter.chapter}", card.title
    assert_equal :unread, card.status
    assert_nil card.progress_percent
  end

  test "uses the localized chapter title while preserving the quiz verse destination" do
    suggestion = @suggestions.first

    %i[es fr en].concat([ :"pt-BR" ]).each do |locale|
      card = Hubs::ReadingCards.call(person: @person, locale:, suggestions: [ suggestion ]).sole
      chapter = Scriptures::Reference.from_study(study: suggestion.study, locale:, verse: 1)

      assert_equal "#{chapter.book_label} #{chapter.chapter}", card.title
      assert_equal suggestion.cite, card.cite
    end
  end

  test "uses the persisted reading progress state without turning an accidental opening into in progress" do
    unread, active, completed = @suggestions
    create_progress(unread, ratio: 0.07)
    create_progress(active, ratio: 0.42)
    create_progress(completed, ratio: 0.02, completed_at: Time.current)

    cards = Hubs::ReadingCards.call(person: @person, locale: :fr, suggestions: @suggestions)

    assert_equal :unread, cards.find { |card| card.study == unread.study }.status
    active_card = cards.find { |card| card.study == active.study }
    assert_equal :in_progress, active_card.status
    assert_equal 42, active_card.progress_percent
    completed_card = cards.find { |card| card.study == completed.study }
    assert_equal :completed, completed_card.status
    assert_equal 100, completed_card.progress_percent
  end

  test "preloads the recommended chapter progresses in one query" do
    @suggestions.each_with_index do |suggestion, index|
      create_progress(suggestion, ratio: (index + 1) * 0.12)
    end

    assert_operator sql_queries {
      Hubs::ReadingCards.call(person: @person, locale: :fr, suggestions: @suggestions)
    }, :<=, 1
  end

  private

    def quiz_suggestions(limit)
      QuizDefinition.catalog.all_questions.each_with_object([]) do |question, rows|
        next if rows.any? { |row| row.study == question.scripture.study }

        rows << Quizzes::ReadingSuggestions::Suggestion.new(
          pack_id: question.pack_id,
          question_id: question.id,
          cite: question.scripture.cite,
          study: question.scripture.study
        )
        break rows if rows.size == limit
      end
    end

    def create_progress(suggestion, ratio:, completed_at: nil)
      ScriptureReadingProgress.create!(
        person: @person,
        locale: "fr",
        reference: suggestion.study,
        first_opened_at: 1.hour.ago,
        last_opened_at: Time.current,
        last_verse: 1,
        last_offset: 0,
        progress_ratio: ratio,
        completed_at:
      )
    end

    def sql_queries(&block)
      count = 0
      callback = lambda do |_name, _start, _finish, _id, payload|
        count += 1 unless payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION])
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      count
    end
end
