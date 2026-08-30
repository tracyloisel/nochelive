module Studies
  class AnswerClock
    MAX_DURATION_MS = 1_800_000

    def self.elapsed_ms(run, at: Time.current)
      started_at = run.asked_at || at
      milliseconds = ((at - started_at) * 1000).round.clamp(0, MAX_DURATION_MS)
      milliseconds
    end
  end
end
