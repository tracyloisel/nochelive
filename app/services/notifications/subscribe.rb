module Notifications
  class Subscribe
    class Error < StandardError
      attr_reader :code

      def initialize(code)
        @code = code
        super(code.to_s)
      end
    end

    def self.call(person:, device_token:, subscription:, locale:, time_zone:, user_agent_family: nil, reassign: false)
      new(person:, device_token:, subscription:, locale:, time_zone:, user_agent_family:, reassign:).call
    end

    def initialize(person:, device_token:, subscription:, locale:, time_zone:, user_agent_family:, reassign:)
      @person = person
      @device_token = device_token.to_s
      @subscription = subscription.to_h.deep_symbolize_keys
      @locale = Locale.cast(locale)
      @time_zone = time_zone.to_s
      @user_agent_family = user_agent_family.to_s.first(40).presence
      @reassign = ActiveModel::Type::Boolean.new.cast(reassign)
    end

    def call
      raise Error.new(:person_required) unless @person
      raise Error.new(:device_required) if @device_token.blank?

      endpoint = @subscription[:endpoint].to_s
      keys = @subscription[:keys].to_h.deep_symbolize_keys
      raise Error.new(:invalid_subscription) if endpoint.blank? || keys[:p256dh].blank? || keys[:auth].blank?
      raise Error.new(:invalid_subscription) unless valid_endpoint?(endpoint)

      digest = Notifications::Cipher.digest(endpoint)
      device_digest = Notifications::Cipher.device_digest(@device_token)
      row = WebPushSubscription.find_or_initialize_by(endpoint_digest: digest)
      if row.persisted? && row.person_id != @person.id && !@reassign
        raise Error.new(:reassignment_required)
      end

      ApplicationRecord.transaction do
        WebPushSubscription.active.where(device_token_digest: device_digest).where.not(id: row.id).update_all(revoked_at: Time.current, updated_at: Time.current)
        row.assign_attributes(
          person: @person,
          device_token_digest: device_digest,
          endpoint: endpoint,
          p256dh: keys[:p256dh],
          auth: keys[:auth],
          locale: @locale,
          time_zone: normalized_time_zone,
          user_agent_family: @user_agent_family,
          revoked_at: nil,
          failure_count: 0
        )
        row.save!
      end
      row
    rescue URI::InvalidURIError
      raise Error.new(:invalid_subscription)
    end

    private

      def valid_endpoint?(endpoint)
        uri = URI.parse(endpoint)
        uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
      end

      def normalized_time_zone
        TZInfo::Timezone.get(@time_zone)
        @time_zone
      rescue TZInfo::InvalidTimezoneIdentifier
        "UTC"
      end
  end
end
