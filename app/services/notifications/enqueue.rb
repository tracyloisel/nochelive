module Notifications
  class Enqueue
    def self.call(person:, kind:, subject:, destination:, dedupe_token: nil, scheduled_for: Time.current, subscriptions: nil)
      new(person:, kind:, subject:, destination:, dedupe_token:, scheduled_for:, subscriptions:).call
    end

    def initialize(person:, kind:, subject:, destination:, dedupe_token:, scheduled_for:, subscriptions:)
      @person = person
      @kind = kind.to_s
      @subject = subject
      @destination = destination
      @dedupe_token = dedupe_token.presence || subject_key
      @scheduled_for = scheduled_for
      @subscriptions = subscriptions
    end

    def call
      return [] unless Notifications::Feature.delivery_enabled?
      preference = @person.notification_preference
      return [] unless preference&.enabled_for?(@kind)

      rows = []
      Array(@subscriptions || @person.web_push_subscriptions.active.to_a).each do |subscription|
        delivery, created = create_delivery(subscription)
        next unless delivery

        rows << delivery
        queue = delivery.transactional? ? :notifications_transactional : :notifications_editorial
        NotificationDeliveryJob.set(queue:).perform_later(delivery) if created
      end
      rows
    end

    private

      def create_delivery(subscription)
        key = [ @kind, @dedupe_token, "subscription", subscription.id ].join(":")
        created = false
        delivery = NotificationDelivery.find_or_create_by!(dedupe_key: key) do |row|
          created = true
          row.assign_attributes(
            web_push_subscription: subscription,
            person: @person,
            kind: @kind,
            subject: @subject,
            destination: @destination,
            scheduled_for: @scheduled_for,
            status: "queued"
          )
        end
        [ delivery, created ]
      rescue ActiveRecord::RecordNotUnique
        [ NotificationDelivery.find_by(dedupe_key: key), false ]
      end

      def subject_key
        @subject ? "#{@subject.class.base_class.name.underscore}-#{@subject.id}" : @scheduled_for.to_date.iso8601
      end
  end
end
