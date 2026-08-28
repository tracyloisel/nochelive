module Notifications
  class UpdatePreferences
    class Error < StandardError; end

    def self.call(person:, device_token:, category:, enabled:, attributes: {})
      new(person:, device_token:, category:, enabled:, attributes:).call
    end

    def initialize(person:, device_token:, category:, enabled:, attributes:)
      @person = person
      @device_token = device_token.to_s
      @category = category.to_s
      @enabled = ActiveModel::Type::Boolean.new.cast(enabled)
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      raise Error, "person required" unless @person
      raise Error, "unknown category" unless NotificationPromptState::CATEGORIES.include?(@category)
      ensure_active_subscription! if @enabled

      preference = @person.notification_preference || @person.create_notification_preference!
      preference.with_lock do
        assign_verse_options(preference) if @category == "verses"
        @enabled ? preference.enable!(@category) : preference.disable!(@category)
      end
      preference
    end

    private

      def ensure_active_subscription!
        digest = Notifications::Cipher.device_digest(@device_token)
        return if @person.web_push_subscriptions.active.exists?(device_token_digest: digest)

        raise Error, "active subscription required"
      end

      def assign_verse_options(preference)
        frequency = @attributes[:verse_frequency].presence
        local_time = @attributes[:verse_local_time].presence
        preference.verse_frequency = frequency if frequency
        preference.verse_local_time = local_time if local_time
        preference.quiet_hours_start = @attributes[:quiet_hours_start] if @attributes[:quiet_hours_start].present?
        preference.quiet_hours_end = @attributes[:quiet_hours_end] if @attributes[:quiet_hours_end].present?
        preference.save! if preference.changed?
      end
  end
end
