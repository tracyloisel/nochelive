module Nights
  class Configure
    EDITABLE = %i[starts_at presenter_locale broadcast_delay_ms missionary_names].freeze

    def self.call(night:, attributes:, broadcast: true)
      new(night:, attributes:, broadcast:).call
    end

    def initialize(night:, attributes:, broadcast:)
      @night = night
      @attributes = attributes.to_h.symbolize_keys.slice(*EDITABLE)
      @broadcast = broadcast
    end

    def call
      GameSession.transaction do
        @night.update!(night_attributes)
        replace_missionaries! if @attributes.key?(:missionary_names)
      end
      @night.reload.tap { |night| night.broadcast_state if @broadcast }
    end

    private

      def night_attributes
        @attributes.slice(:starts_at, :presenter_locale, :broadcast_delay_ms)
      end

      def replace_missionaries!
        names = Array(@attributes[:missionary_names]).map { |name| name.to_s.strip }
        raise ArgumentError, "missionary_names cannot contain blank names" if names.any?(&:blank?)

        names = names.uniq
        @night.missionaries.where.not(name: names).destroy_all
        names.each { |name| @night.missionaries.find_or_create_by!(name:) }
      end
  end
end
