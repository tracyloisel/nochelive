require "test_helper"

class DuelReminderJobTest < ActiveJob::TestCase
  test "creates at most one reminder while an invitation remains actionable" do
    invitation = duel_invitations(:named_pili_invitation)

    with_web_push_enabled do
      assert_difference -> { NotificationDelivery.where(kind: "duel_reminder").count }, 1 do
        DuelReminderJob.perform_now(invitation)
        DuelReminderJob.perform_now(invitation)
      end
    end
  end

  test "does nothing after claim or while the friend is present" do
    invitation = duel_invitations(:named_pili_invitation)

    with_web_push_enabled do
      invitation.update!(status: "claimed", claimed_by_person: people(:carmen_garcia), claimed_at: Time.current)
      assert_no_difference -> { NotificationDelivery.count } do
        DuelReminderJob.perform_now(invitation)
      end

      invitation.update!(status: "open", claimed_by_person: nil, claimed_at: nil)
      mark_person_online(people(:carmen_garcia))
      assert_no_difference -> { NotificationDelivery.count } do
        DuelReminderJob.perform_now(invitation)
      end
    end
  end
end
