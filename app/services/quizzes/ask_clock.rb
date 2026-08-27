module Quizzes
  class AskClock
    UNTIMED_CAP_MS = 1_800_000

    def self.opening_attrs(question, at: Time.current)
      {
        asked_at: at,
        ends_at: question.timed? ? at + question.duration.seconds : nil
      }
    end

    def self.elapsed_ms(run, question:, at: Time.current)
      started = run.asked_at || run.opened_at
      ms = ((at - started) * 1000).round
      ms = 0 if ms.negative?
      [ ms, cap_ms(question) ].min
    end

    def self.cap_ms(question)
      question.timed? ? question.duration.to_i * 1000 : UNTIMED_CAP_MS
    end
    private_class_method :cap_ms
  end
end
