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

        locked.update!(
          position: @position,
          ends_at: answer || locked.finished? ? nil : timer_for(question)
        )
        Draw.frame(locked.reload)
      end
    end

    private

      def timer_for(question)
        question.timed? ? question.duration.seconds.from_now : nil
      end
  end
end
