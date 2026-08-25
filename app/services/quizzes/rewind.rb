module Quizzes
  class Rewind
    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(@run.id)
        if locked.finished?
          locked.update!(status: "open", ends_at: nil)
          return Draw.frame(locked.reload)
        end

        return Draw.frame(locked) if locked.position <= 1

        prev = locked.position - 1
        question = locked.pack.question_at(prev)
        return Draw.frame(locked) unless locked.quiz_answers.exists?(question_id: question.id)

        locked.update!(position: prev, ends_at: nil)
        Draw.frame(locked.reload)
      end
    end
  end
end
