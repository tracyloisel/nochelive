require "test_helper"

class DuelReminderJobTest < ActiveJob::TestCase
  test "creates at most one reminder while a duel remains actionable" do
    duel = StreetDuel.create!(
      challenger_person: people(:pili), opponent_person: people(:carmen_garcia),
      ward: wards(:demo), pack_id: "coronas", token: "single-reminder",
      status: "challenger_done", challenger_score: 42, expires_at: 3.days.from_now
    )

    with_web_push_enabled do
      assert_difference -> { NotificationDelivery.where(kind: "duel_reminder").count }, 1 do
        DuelReminderJob.perform_now(duel)
        DuelReminderJob.perform_now(duel)
      end
    end
  end

  test "does nothing after resolution expiry or when the opponent is present" do
    duel = StreetDuel.create!(
      challenger_person: people(:pili), opponent_person: people(:carmen_garcia),
      ward: wards(:demo), pack_id: "coronas", token: "blocked-reminder",
      status: "resolved", challenger_score: 42, opponent_score: 51,
      expires_at: 3.days.from_now
    )

    with_web_push_enabled do
      assert_no_difference -> { NotificationDelivery.count } do
        DuelReminderJob.perform_now(duel)
      end

      duel.update!(status: "challenger_done", opponent_score: nil)
      person_devices(:carmen_phone).update!(last_seen_at: Time.current)
      assert_no_difference -> { NotificationDelivery.count } do
        DuelReminderJob.perform_now(duel)
      end
    end
  end
end
