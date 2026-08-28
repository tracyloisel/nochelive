module Notifications
  class ScheduleVerses
    WINDOW = 15.minutes
    THREE_WEEKLY_DAYS = [ 1, 3, 5 ].freeze

    def self.call(now: Time.current)
      new(now:).call
    end

    def initialize(now:)
      @now = now
    end

    def call
      return [] unless Notifications::Feature.delivery_enabled?

      deliveries = []
      NotificationPreference.where(verses_enabled: true).includes(person: :web_push_subscriptions).find_each do |preference|
        active = preference.person.web_push_subscriptions.select(&:active?)
        next if active.empty?

        active.group_by(&:time_zone).each_value do |subscriptions|
          local_now = @now.in_time_zone(subscriptions.first.time_zone)
          next unless due?(preference, local_now)

          entry = Notifications::VerseCatalog.for(local_now.to_date)
          subscriptions.group_by(&:locale).each do |locale, localized_subscriptions|
            deliveries.concat Notifications::Enqueue.call(
              person: preference.person,
              kind: "daily_verse",
              subject: nil,
              destination: entry.destination(locale),
              dedupe_token: "person-#{preference.person_id}-date-#{local_now.to_date}",
              subscriptions: localized_subscriptions
            )
          end
        end
      end
      deliveries
    end

    private

      def due?(preference, local_now)
        return false if preference.verse_frequency == "three_weekly" && !THREE_WEEKLY_DAYS.include?(local_now.wday)
        return false if quiet?(preference, local_now)

        target = local_now.change(
          hour: preference.verse_local_time.hour,
          min: preference.verse_local_time.min,
          sec: 0
        )
        local_now >= target && local_now < target + WINDOW
      end

      def quiet?(preference, local_now)
        minute = local_now.hour * 60 + local_now.min
        start_minute = preference.quiet_hours_start.hour * 60 + preference.quiet_hours_start.min
        end_minute = preference.quiet_hours_end.hour * 60 + preference.quiet_hours_end.min
        if start_minute < end_minute
          minute >= start_minute && minute < end_minute
        else
          minute >= start_minute || minute < end_minute
        end
      end
  end
end
