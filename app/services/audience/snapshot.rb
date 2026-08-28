module Audience
  class Snapshot
    PHASES = %w[lobby intro open locked revealed finished].freeze

    attr_reader :night, :round, :now

    def initialize(night:, now: Time.current)
      @night = night
      @round = night.current_round_run
      @now = now
    end

    def phase
      return "finished" if night.finished?
      return "lobby" if night.lobby? || round.blank? || round.pending?
      return "intro" if before_delayed_open?
      return "open" if delayed_lock_pending?
      return "locked" if delayed_reveal_pending?
      return "revealed" if round.revealed? || round.completed?
      return "locked" if round.locked? || round.answering?
      return "open" if round.open?

      "intro"
    end

    PHASES.each do |name|
      define_method("#{name}?") { phase == name }
    end

    def accepting_responses?
      open? && round&.definition&.has_choices?
    end

    def reveal_visible?
      revealed?
    end

    def next_transition_at
      delayed_cues.select { |cue| cue > now }.min
    end

    def refresh_in_ms
      return unless next_transition_at

      [ ((next_transition_at - now) * 1000).ceil + 120, 120 ].max
    end

    def seconds_left
      return 0 unless round&.ends_at

      [ ((round.ends_at + delay - now)).ceil, 0 ].max
    end

    def progress_percent
      duration = round&.definition&.duration.to_i
      return 0 if duration <= 0

      ((seconds_left * 100.0) / duration).clamp(0, 100).round
    end

    private

      def delay
        (night.broadcast_delay_ms.to_i / 1000.0).seconds
      end

      def delayed_open_at
        round&.opened_at && round.opened_at + delay
      end

      def delayed_lock_at
        round&.locked_at && round.locked_at + delay
      end

      def delayed_reveal_at
        round&.revealed_at && round.revealed_at + delay
      end

      def delayed_cues
        [ delayed_open_at, delayed_lock_at, delayed_reveal_at ].compact
      end

      def before_delayed_open?
        delayed_open_at.present? && now < delayed_open_at
      end

      def delayed_lock_pending?
        delayed_lock_at.present? && now < delayed_lock_at
      end

      def delayed_reveal_pending?
        delayed_reveal_at.present? && now < delayed_reveal_at
      end
  end
end
