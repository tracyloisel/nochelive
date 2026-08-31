require "test_helper"

class Hubs::WeeklyReadingCardsTest < ActiveSupport::TestCase
  setup do
    @person = people(:pili)
    @week = Struct.new(:id).new(741)
    content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
    @quiz = StudyQuizVersion.new(content:)
    @readings = @quiz.readings(:fr)
    ScriptureReadingProgress.where(person: @person, locale: "fr", reference: @readings.map { |reading| reading.fetch("study") }).delete_all
  end

  test "creates one card per published chapter in editorial order and de-duplicates a repeated study" do
    content = @quiz.content.deep_dup
    content["readings"] << content.fetch("readings").first.deep_dup
    @quiz.content = content

    cards = Hubs::WeeklyReadingCards.call(person: @person, week: @week, quiz: @quiz, locale: :fr)
    expected_studies = @readings.map { |reading| reading.fetch("study") }.uniq

    assert_equal expected_studies, cards.map(&:study)
    first_reference = Scriptures::Reference.from_study(study: @readings.first.fetch("study"), locale: :fr, verse: 1)
    assert_equal "#{first_reference.book_label} #{first_reference.chapter}", cards.first.title
    assert_equal @readings.first.fetch("label"), cards.first.cite
    assert_equal "media/study/psalms-refuge-2026.png", cards.first.artwork
    assert_equal @week.id, cards.first.study_unit_id
  end

  test "uses the published localized reading labels in each supported language" do
    %i[es fr en].concat([ :"pt-BR" ]).each do |locale|
      cards = Hubs::WeeklyReadingCards.call(person: @person, week: @week, quiz: @quiz, locale:)

      expected_titles = @quiz.readings(locale).map do |reading|
        reference = Scriptures::Reference.from_study(study: reading.fetch("study"), locale:, verse: 1)
        "#{reference.book_label} #{reference.chapter}"
      end.uniq
      assert_equal expected_titles, cards.map(&:title)
    end
  end

  test "uses ScriptureReadingProgress without treating a short opening as an active reading" do
    unread, active, completed = @readings.first(3)
    create_progress(unread, ratio: 0.07)
    create_progress(active, ratio: 0.42)
    create_progress(completed, ratio: 0.02, completed_at: Time.current)

    cards = Hubs::WeeklyReadingCards.call(person: @person, week: @week, quiz: @quiz, locale: :fr)

    assert_equal :unread, cards.find { |card| card.study == unread.fetch("study") }.status
    active_card = cards.find { |card| card.study == active.fetch("study") }
    assert_equal :in_progress, active_card.status
    assert_equal 42, active_card.progress_percent
    completed_card = cards.find { |card| card.study == completed.fetch("study") }
    assert_equal :completed, completed_card.status
    assert_equal 100, completed_card.progress_percent
  end

  test "preloads all weekly reading progresses in one query" do
    @readings.first(3).each_with_index do |reading, index|
      create_progress(reading, ratio: (index + 1) * 0.12)
    end

    assert_operator sql_queries {
      Hubs::WeeklyReadingCards.call(person: @person, week: @week, quiz: @quiz, locale: :fr)
    }, :<=, 1
  end

  test "omits an invalid published reading instead of inventing a chapter card" do
    content = @quiz.content.deep_dup
    content["readings"] = [
      {
        "study" => "not-a-scripture/chapter",
        "labels" => { "fr" => "Lecture indisponible" }
      }
    ]
    @quiz.content = content

    assert_empty Hubs::WeeklyReadingCards.call(person: @person, week: @week, quiz: @quiz, locale: :fr)
  end

  test "keeps a visitor's weekly cards honest without querying personal progress" do
    assert_equal 0, sql_queries {
      cards = Hubs::WeeklyReadingCards.call(person: nil, week: @week, quiz: @quiz, locale: :fr)
      assert cards.all? { |card| card.status == :unread && card.progress_percent.nil? }
    }
  end

  private

    def create_progress(reading, ratio:, completed_at: nil)
      ScriptureReadingProgress.create!(
        person: @person,
        locale: "fr",
        reference: reading.fetch("study"),
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
