module Notifications
  class ScheduleNights
    REMINDERS = {
      "night_tomorrow" => 24.hours,
      "night_starting_soon" => 15.minutes
    }.freeze
    LOOKBACK = 10.minutes

    def self.call(at: Time.current)
      new(at:).call
    end

    def initialize(at:)
      @at = at
      @helpers = Rails.application.routes.url_helpers
    end

    def call
      return [] unless Notifications::Feature.enabled?

      REMINDERS.flat_map do |kind, advance|
        due_nights(advance).flat_map { |night| enqueue_night(night, kind) }
      end
    end

    private

      def due_nights(advance)
        GameSession.where(status: "lobby", starts_at: (@at + advance - LOOKBACK)..(@at + advance))
          .includes(:ward)
      end

      def enqueue_night(night, kind)
        joined_person_ids = night.players.where.not(person_id: nil).distinct.pluck(:person_id)
        eligible_people(night).where.not(id: joined_person_ids).find_each.flat_map do |person|
          Notifications::Enqueue.call(
            person:,
            kind:,
            subject: night,
            destination: @helpers.night_name_path(night.code),
            dedupe_token: [ night.id, night.starts_at.to_i, kind ].join(":"),
            scheduled_for: @at
          )
        end
      end

      def eligible_people(night)
        Person.where(ward_id: night.ward_id)
          .joins(:notification_preference)
          .where(notification_preferences: { nights_enabled: true })
      end
  end
end
