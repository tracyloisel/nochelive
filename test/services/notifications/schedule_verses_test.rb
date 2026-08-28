require "test_helper"

class Notifications::ScheduleVersesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @preference = notification_preferences(:carmen_notifications)
    @preference.update!(
      verses_enabled: true, verses_enabled_at: 1.day.ago,
      verse_frequency: "daily", verse_local_time: "08:00"
    )
  end

  test "schedules by the subscription timezone across the European DST jump" do
    now = Time.utc(2026, 3, 29, 6, 5) # 08:05 in Europe/Madrid after the DST jump.

    with_web_push_enabled do
      assert_difference -> { NotificationDelivery.where(kind: "daily_verse").count }, 1 do
        Notifications::ScheduleVerses.call(now:)
      end
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::ScheduleVerses.call(now: now + 5.minutes)
      end
    end

    delivery = NotificationDelivery.where(kind: "daily_verse").order(:id).last
    expected = Notifications::VerseCatalog.for(now.in_time_zone("Europe/Madrid").to_date)
    assert_equal expected.destination("es"), delivery.destination
  end

  test "respects the overnight quiet period and the three-weekly calendar" do
    @preference.update!(verse_frequency: "three_weekly", verse_local_time: "07:45")

    with_web_push_enabled do
      monday_in_quiet_hours = Time.find_zone!("Europe/Madrid").local(2026, 8, 31, 7, 50)
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::ScheduleVerses.call(now: monday_in_quiet_hours)
      end

      @preference.update!(verse_local_time: "08:00")
      tuesday = Time.find_zone!("Europe/Madrid").local(2026, 9, 1, 8, 5)
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::ScheduleVerses.call(now: tuesday)
      end
    end
  end

  test "reconstructs delayed content from the stored destination" do
    entry = Notifications::VerseCatalog.entries.first
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push),
      person: people(:carmen_garcia), kind: "daily_verse",
      dedupe_key: "delayed-editorial-content", destination: entry.destination("es")
    )

    travel_to 20.days.from_now do
      payload = Notifications::Content.call(delivery)
      assert_includes payload[:body], entry.citation("es")
      assert_equal "#{entry.destination("es")}?nl_delivery=#{delivery.id}", payload.dig(:data, :path)
    end
  end
end
