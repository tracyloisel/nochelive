module Notifications
  class Deliver
    class TransientError < StandardError; end

    def self.call(delivery:)
      new(delivery:).call
    end

    def initialize(delivery:)
      @delivery = delivery
    end

    def call
      @delivery.with_lock do
        @delivery.reload
        return @delivery if terminal?
        unless deliverable?
          @delivery.cancel!(code: "no_longer_deliverable")
          return @delivery
        end

        @delivery.update!(status: "sending", attempt_count: @delivery.attempt_count + 1, error_code: nil)
        Notifications::Sender.call(
          subscription: @delivery.web_push_subscription,
          payload: Notifications::Content.call(@delivery),
          ttl: ttl,
          urgency: @delivery.transactional? ? "high" : "normal"
        )
        @delivery.web_push_subscription.mark_success!
        @delivery.update!(status: "sent", sent_at: Time.current, error_code: nil)
      end
      @delivery
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      revoke!(:subscription_expired)
    rescue WebPush::TooManyRequests
      transient!(:rate_limited)
    rescue WebPush::PushServiceError, Net::OpenTimeout, Net::ReadTimeout, SocketError
      transient!(:push_service_unavailable)
    rescue WebPush::Unauthorized
      permanent!(:vapid_rejected)
    rescue WebPush::PayloadTooLarge, ArgumentError, JSON::GeneratorError
      permanent!(:invalid_payload)
    rescue WebPush::ResponseError
      permanent!(:push_rejected)
    end

    private

      def terminal?
        @delivery.sent? || @delivery.opened? || @delivery.cancelled? || @delivery.failed?
      end

      def deliverable?
        return false unless Notifications::Feature.enabled? && Notifications::Feature.vapid_configured?
        return false unless @delivery.web_push_subscription&.active?
        preference = @delivery.person.notification_preference
        return false unless preference&.enabled_for?(@delivery.kind)

        duel = @delivery.subject if @delivery.subject_type == "StreetDuel"
        return false if duel&.expired?
        return duel.resolved? if @delivery.kind == "duel_result"
        return duel.active? if %w[duel_invitation duel_reminder].include?(@delivery.kind)

        true
      end

      def ttl
        if @delivery.subject_type == "StreetDuel"
          [ (@delivery.subject.expires_at - Time.current).to_i, 60 ].max.clamp(60, 7.days.to_i)
        elsif @delivery.kind == "daily_verse"
          12.hours.to_i
        else
          1.day.to_i
        end
      end

      def revoke!(code)
        @delivery.web_push_subscription.revoke!
        permanent!(code)
      end

      def permanent!(code)
        @delivery.web_push_subscription.mark_failure!
        @delivery.update!(status: "failed", error_code: code.to_s)
        @delivery
      end

      def transient!(code)
        @delivery.web_push_subscription.mark_failure!
        @delivery.update!(status: "queued", error_code: code.to_s)
        raise TransientError, code.to_s
      end
  end
end
