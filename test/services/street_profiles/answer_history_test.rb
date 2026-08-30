require "test_helper"

class StreetProfiles::AnswerHistoryTest < ActiveSupport::TestCase
  test "combines localized adventure and word answers with their verdict and duration" do
    person = people(:pili)
    adventure_run = quiz_runs(:pili_coronas)
    adventure_question = QuizDefinition.catalog.find_pack("coronas").question_at(1)
    adventure_run.quiz_answers.create!(
      device_digest: adventure_run.device_digest,
      pack_id: adventure_run.pack_id,
      question_id: adventure_question.id,
      choice_key: "saul",
      correct: false,
      duration_ms: 4_200
    )
    word_run, word_question = create_word_run(person:)
    word_run.study_answers.create!(
      question_key: word_question.fetch("key"),
      choice_key: word_question.fetch("correct_choice"),
      correct: true,
      duration_ms: 2_600
    )

    history = StreetProfiles::AnswerHistory.call(person:, locale: :fr)

    assert_equal 2, history.total_answers
    assert_equal 1, history.correct_answers
    assert_equal 3_400, history.average_duration_ms
    assert_equal %i[word adventure], history.sessions.map(&:kind)

    adventure = history.sessions.find { |session| session.kind == :adventure }.answers.first
    assert_equal "Qui a oint David quand il était encore un garçon ?", adventure.question
    assert_equal "Saül", adventure.chosen_answer
    assert_equal "Samuel", adventure.correct_answer
    refute adventure.correct
    assert_equal 4_200, adventure.duration_ms

    word = history.sessions.find { |session| session.kind == :word }.answers.first
    assert word.correct
    assert_equal 2_600, word.duration_ms
    assert_equal word.chosen_answer, word.correct_answer
  end

  test "paginates sessions and never includes another profile's answers" do
    person = people(:pili)
    question = QuizDefinition.catalog.find_pack("coronas").question_at(1)
    9.times do |index|
      run = QuizRun.create!(
        person:,
        device_digest: "history-#{index}",
        pack_id: "coronas",
        position: 1,
        score: 0,
        status: "finished",
        opened_at: (index + 1).hours.ago
      )
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: true,
        duration_ms: 1_000
      )
    end
    other = quiz_runs(:carmen_coronas)
    other.quiz_answers.create!(
      device_digest: other.device_digest,
      pack_id: other.pack_id,
      question_id: question.id,
      choice_key: question.correct_choice,
      correct: true,
      duration_ms: 99_000
    )

    first = StreetProfiles::AnswerHistory.call(person:, page: 1)
    second = StreetProfiles::AnswerHistory.call(person:, page: 2)

    assert_equal 9, first.total_sessions
    assert_equal 2, first.total_pages
    assert_equal 8, first.sessions.size
    assert_equal 1, second.sessions.size
    assert_equal 9, first.total_answers
    assert_equal 1_000, first.average_duration_ms
  end

  private

    def create_word_run(person:)
      program = StudyProgram.create!(
        slug: "answer-history-program",
        title: "Viens et suis-moi 2026",
        year: 2026,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/history-program"
      )
      unit = program.study_units.create!(
        slug: "answer-history-week",
        kind: "week",
        position: 1,
        title: "24–30 août : Psaumes 49–86",
        source_url: "https://example.test/history-week",
        status: "published"
      )
      content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
      version = unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      run = StudyRun.create!(
        person:,
        study_quiz_version: version,
        device_digest: "word-history",
        position: 1,
        score: 1,
        status: "completed",
        opened_at: 1.hour.ago,
        completed_at: Time.current
      )
      [ run, version.localized_question(1, :fr) ]
    end
end
