module Quizzes
  class Submit
    def self.call(run:, choice_key:)
      new(run:, choice_key:).call
    end

    def initialize(run:, choice_key:)
      @run = run
      @choice_key = choice_key.to_s
    end

    def call
      raise "Quiz closed" unless @run.open?

      question = @run.question
      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(@run.id)
        raise "Quiz closed" unless locked.open?

        existing = locked.quiz_answers.find_by(question_id: question.id)
        return existing if existing

        late = locked.ends_at.present? && Time.current > locked.ends_at
        blank = @choice_key.blank?
        correct = !late && !blank && @choice_key == question.correct_choice
        answer = locked.quiz_answers.create!(
          device_digest: locked.device_digest,
          pack_id: locked.pack_id,
          question_id: question.id,
          choice_key: @choice_key.presence,
          correct: correct,
          duration_ms: AskClock.elapsed_ms(locked, question:)
        )
        locked.increment!(:score, question.points) if correct
        answer
      end
    end
  end
end
