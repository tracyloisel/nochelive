module Notifications
  class Content
    def self.call(delivery)
      new(delivery).call
    end

    def initialize(delivery)
      @delivery = delivery
      @locale = Locale.i18n(delivery.web_push_subscription&.locale || I18n.default_locale)
    end

    def call
      I18n.with_locale(@locale) do
        {
          title: title,
          body: body,
          tag: tag,
          icon: "/icon-192.png",
          badge: "/favicon-32.png",
          data: {
            path: tracked_destination,
            delivery_id: @delivery.id,
            receipt_path: receipt_path
          }
        }
      end
    end

    private

      def title
        I18n.t("notifications.push.#{@delivery.kind}.title")
      end

      def body
        case @delivery.kind
        when "duel_invitation", "duel_reminder", "duel_result"
          duel_body
        when "daily_verse"
          entry = daily_verse_entry
          I18n.t("notifications.push.daily_verse.body", reference: entry.citation(@locale))
        when "study_reading"
          I18n.t("notifications.push.study_reading.body", title: @delivery.subject&.display_heading(@locale))
        when "night_tomorrow", "night_starting_soon"
          I18n.t("notifications.push.#{@delivery.kind}.body", time: night_local_time)
        end
      end

      def night_local_time
        zone = @delivery.web_push_subscription&.time_zone || "UTC"
        I18n.l(@delivery.subject.starts_at.in_time_zone(zone), format: "%H:%M")
      end

      def duel_body
        subject = @delivery.subject
        if subject.is_a?(::DuelInvitation)
          return I18n.t(
            "notifications.push.#{@delivery.kind}.body",
            name: subject.challenger_person.display_name
          )
        end

        other = subject.other_person_for(@delivery.person)
        key = if @delivery.kind == "duel_result"
          subject.winner_person.nil? ? "tie" : (subject.winner_person.id == @delivery.person_id ? "won" : "finished")
        else
          @delivery.kind
        end
        I18n.t("notifications.push.#{key}.body", name: other&.display_name || I18n.t("street.share_guest"))
      end

      def tracked_destination
        separator = @delivery.destination.include?("?") ? "&" : "?"
        "#{@delivery.destination}#{separator}nl_delivery=#{@delivery.id}"
      end

      def receipt_path
        token = @delivery.signed_id(
          purpose: Notifications::AcknowledgeReceipt::PURPOSE,
          expires_in: 8.days
        )
        Rails.application.routes.url_helpers.notifications_receipt_path(token:)
      end

      def local_date
        Time.current.in_time_zone(@delivery.web_push_subscription&.time_zone || "UTC").to_date
      end

      def daily_verse_entry
        Notifications::VerseCatalog.entries.find do |entry|
          entry.destination(@delivery.web_push_subscription&.locale || @locale) == @delivery.destination
        end || Notifications::VerseCatalog.for(local_date)
      end

      def tag
        subject = @delivery.subject
        subject ? "#{@delivery.kind.tr('_', '-')}-#{subject.id}" : "#{@delivery.kind.tr('_', '-')}-#{local_date}"
      end
  end
end
