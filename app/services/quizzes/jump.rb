module Quizzes
  class Jump
    def self.call(run:, position:)
      new(run:, position:).call
    end

    def initialize(run:, position:)
      @run = run
      @position = position.to_i
    end

    def call
      raise "Invalid question" unless @position.positive? && @position <= @run.pack.questions.size

      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(@run.id)
        if locked.finished?
          locked.update!(status: "open", ends_at: nil)
          locked.reload
        end

        question = locked.pack.question_at(@position)
        answer = locked.quiz_answers.find_by(question_id: question.id)
        raise "Not yet answered" if @position < locked.position && answer.nil?
        raise "Not yet reached" if @position > locked.position

        attrs = { position: @position }
        if answer || locked.finished?
          attrs[:ends_at] = nil
        else
          attrs.merge!(AskClock.opening_attrs(question))
        end
        locked.update!(attrs)
        Draw.frame(locked.reload)
      end
    end
  end
end
