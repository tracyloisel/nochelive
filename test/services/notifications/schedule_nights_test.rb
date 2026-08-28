require "test_helper"

class Notifications::ScheduleNightsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "schedules one day-before reminder with an exact session deep link and deduplicates it" do
    freeze_time do
      night = game_sessions(:elias)
      night.update!(status: "lobby", starts_at: 24.hours.from_now)
      notification_preferences(:carmen_notifications).enable!("nights")

      with_web_push_enabled do
        assert_difference -> { NotificationDelivery.where(kind: "night_tomorrow").count }, 1 do
          Notifications::ScheduleNights.call(at: Time.current)
        end
        assert_no_difference -> { NotificationDelivery.count } do
          Notifications::ScheduleNights.call(at: Time.current)
        end
      end

      delivery = NotificationDelivery.find_by!(kind: "night_tomorrow", person: people(:carmen_garcia))
      assert_equal night, delivery.subject
      assert_equal Rails.application.routes.url_helpers.night_name_path(night.code), delivery.destination
      assert_enqueued_jobs 1, only: NotificationDeliveryJob
    end
  end

  test "schedules the fifteen-minute reminder but skips a player who already joined" do
    freeze_time do
      night = game_sessions(:elias)
      night.update!(status: "lobby", starts_at: 15.minutes.from_now)
      preference = notification_preferences(:carmen_notifications)
      preference.enable!("nights")
      night.players.create!(
        person: people(:carmen_garcia), name: "Carmen", role: "participant", location: "room",
        client_token: "already-in-night", avatar_key: "delfin"
      )

      with_web_push_enabled do
        assert_no_difference -> { NotificationDelivery.where(kind: "night_starting_soon").count } do
          Notifications::ScheduleNights.call(at: Time.current)
        end
      end
    end
  end
end
