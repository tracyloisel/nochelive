module Notifications
  class Sender
    class << self
      attr_accessor :transport
    end

    def self.call(subscription:, payload:, ttl:, urgency:)
      if transport
        return transport.call(subscription:, payload:, ttl:, urgency:)
      end

      WebPush.payload_send(
        message: JSON.generate(payload),
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: {
          subject: Notifications::Feature.subject,
          public_key: Notifications::Feature.public_key,
          private_key: Notifications::Feature.private_key
        },
        ttl: ttl,
        urgency: urgency,
        ssl_timeout: 5,
        open_timeout: 5,
        read_timeout: 8
      )
    end
  end
end
