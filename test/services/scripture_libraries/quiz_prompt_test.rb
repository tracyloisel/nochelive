require "test_helper"

module ScriptureLibraries
  class QuizPromptTest < ActiveSupport::TestCase
    test "projects the newest real answer without inventing hesitation" do
      person = create_person
      question = QuizDefinition.catalog.find_question(
        "exp_psalms_nameless_king",
        "ps110_melchisedek_04"
      )
      run = completed_run(person:, pack_id: question.pack_id)
      answer = run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: question.pack_id,
        question_id: question.id,
        choice_key: "b",
        correct: false,
        duration_ms: 12_400
      )

      prompt = QuizPrompt.call(person:, locale: :fr)

      assert_equal question.id, prompt.question_id
      assert_equal "b", prompt.choice_key
      I18n.with_locale(:fr) do
        assert_equal question.copy(:question), prompt.question
        assert_equal question.choice_copy("b"), prompt.selected_answer
        assert_equal question.choice_copy(question.correct_choice), prompt.correct_answer
        assert_equal question.copy(:answer), prompt.explanation
      end
      assert_not prompt.correct?
      assert_equal 12_400, prompt.duration_ms
      assert_equal answer.created_at, prompt.answered_at
      assert_equal "ot/ps/110", prompt.study
      assert_equal "Psaumes 110:4", prompt.cite
      assert_equal "/escrituras/ot/ps/110", URI.parse(prompt.path).path
      assert_equal "fr", Rack::Utils.parse_nested_query(URI.parse(prompt.path).query).fetch("locale")
      refute_respond_to prompt, :hesitated
    end

    test "uses a correct answer and ignores answers from unfinished runs" do
      person = create_person
      finished_question = QuizDefinition.catalog.find_question("coronas", "ungio_david")
      open_question = QuizDefinition.catalog.find_question("coronas", "piedras_arroyo")

      travel_to(2.hours.ago) do
        run = completed_run(person:, pack_id: finished_question.pack_id)
        run.quiz_answers.create!(
          device_digest: run.device_digest,
          pack_id: finished_question.pack_id,
          question_id: finished_question.id,
          choice_key: finished_question.correct_choice,
          correct: true
        )
      end
      open_run = QuizRun.create!(
        person:,
        device_digest: Digest::SHA256.hexdigest("library-prompt-open"),
        pack_id: open_question.pack_id,
        position: 2,
        score: 0,
        status: "open",
        opened_at: Time.current
      )
      open_run.quiz_answers.create!(
        device_digest: open_run.device_digest,
        pack_id: open_question.pack_id,
        question_id: open_question.id,
        choice_key: "tres",
        correct: false
      )
      obsolete_run = completed_run(person:, pack_id: open_question.pack_id)
      obsolete_run.quiz_answers.create!(
        device_digest: obsolete_run.device_digest,
        pack_id: open_question.pack_id,
        question_id: open_question.id,
        choice_key: "obsolete-choice",
        correct: false
      )

      prompt = QuizPrompt.call(person:, locale: :fr)

      assert_equal finished_question.id, prompt.question_id
      assert_predicate prompt, :correct?
      assert_equal finished_question.correct_choice, prompt.choice_key
    end

    test "returns nil without a completed answer" do
      assert_nil QuizPrompt.call(person: nil, locale: :fr)
      assert_nil QuizPrompt.call(person: create_person, locale: :fr)
    end

    private

      def create_person
        Person.create!(
          ward: wards(:demo),
          given_name: "Prompt#{SecureRandom.hex(3)}",
          avatar_key: Player::AVATARS.first,
          locale: "fr"
        )
      end

      def completed_run(person:, pack_id:)
        QuizRun.create!(
          person:,
          device_digest: Digest::SHA256.hexdigest("library-prompt-#{SecureRandom.hex(5)}"),
          pack_id:,
          position: 10,
          score: 0,
          status: "finished",
          opened_at: Time.current
        )
      end
  end
end
