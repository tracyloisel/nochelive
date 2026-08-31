module Nights
  class Configure
    EDITABLE = %i[starts_at quiz_pack_ids].freeze

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
        if @attributes.key?(:starts_at)
          starts_at = @attributes[:starts_at].in_time_zone
          attributes.merge!(starts_at:, ends_at: starts_at + GameSession::DURATION)
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
  end
end
