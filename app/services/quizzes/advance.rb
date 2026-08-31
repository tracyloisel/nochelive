module Quizzes
  class Advance
    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      if @run.finished?
        if @run.live?
          next_run = Nights::QuizSequence.next_after(run: @run)
          return next_run && Draw.frame(next_run, ward: @run.game_session.ward)
        end
        return Draw.new(device_digest: @run.device_digest).start_next(after: @run)
      end

      raise "Answer first" unless @run.settled?

      if @run.last_question?
        Complete.call(run: @run)
        return Draw.frame(@run.reload)
      end

      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(@run.id)
        raise "Answer first" unless locked.settled?

        nxt = locked.position + 1
        question = locked.pack.question_at(nxt)
        locked.update!(position: nxt, **AskClock.opening_attrs(question))
        Draw.frame(locked.reload)
      end
    end
  end
end
