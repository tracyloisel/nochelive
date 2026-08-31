module Nights
  class Configure
    EDITABLE = %i[starts_at quiz_pack_ids duration_hours].freeze

    def self.call(night:, attributes:, broadcast: true)
      new(night:, attributes:, broadcast:).call
    end

    def initialize(night:, attributes:, broadcast:)
      @night = night
      @attributes = attributes.to_h.symbolize_keys.slice(*EDITABLE)
      @broadcast = broadcast
    end

    def call
      raise ArgumentError, "a started Noche Live cannot be rescheduled" if @night.starts_at <= Time.current

      @night.update!(night_attributes)
      Nights::ScheduleLifecycle.call(night: @night)
      @night.reload.tap { |night| night.broadcast_state if @broadcast }
    end

    private

      def night_attributes
        attributes = {}
        duration_hours = normalized_duration_hours
        if @attributes.key?(:starts_at)
          starts_at = @attributes[:starts_at].in_time_zone
          attributes[:starts_at] = starts_at
        end
        if @attributes.key?(:duration_hours)
          attributes[:duration_hours] = duration_hours
        end
        if @attributes.key?(:starts_at) || @attributes.key?(:duration_hours)
          starts_at = attributes.fetch(:starts_at, @night.starts_at)
          attributes[:ends_at] = starts_at + duration_hours.hours
        end
        if @attributes.key?(:quiz_pack_ids)
          ids = Array(@attributes[:quiz_pack_ids]).map { |id| id.to_s.strip }.reject(&:blank?)
          raise ArgumentError, "quiz_ids must contain at least one quiz" if ids.empty?
          raise ArgumentError, "quiz_ids cannot contain duplicates" if ids.uniq.size != ids.size
          ids.each { |id| QuizDefinition.catalog.find_pack(id) }
          attributes.merge!(quiz_pack_ids: ids)
        end
        attributes
      rescue QuizDefinition::Error => error
        raise ArgumentError, error.message
      end

      def normalized_duration_hours
        value = Integer(@attributes.fetch(:duration_hours, @night.duration_hours))
        return value if GameSession::DURATION_HOURS_RANGE.cover?(value)

        raise ArgumentError, "duration_hours must be between 1 and 8"
      rescue TypeError, ArgumentError
        raise ArgumentError, "duration_hours must be between 1 and 8"
      end
  end
end
