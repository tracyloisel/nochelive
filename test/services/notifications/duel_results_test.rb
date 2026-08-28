require "test_helper"

class Notifications::DuelResultsTest < ActiveSupport::TestCase
  test "queues localized results for offline participants with consent" do
    duel = street_duels(:pili_vs_carmen)

    with_web_push_enabled do
      assert_difference -> { NotificationDelivery.where(kind: "duel_result").count }, 1 do
        Notifications::DuelResults.call(duel:)
      end
    end

    delivery = NotificationDelivery.where(kind: "duel_result").order(:id).last
    assert_equal people(:carmen_garcia), delivery.person
    assert_equal Rails.application.routes.url_helpers.street_challenge_path(duel.token), delivery.destination
  end

  test "does not push a result to a player who is already present" do
    duel = street_duels(:pili_vs_carmen)
    person_devices(:carmen_phone).update!(last_seen_at: Time.current)

    with_web_push_enabled do
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::DuelResults.call(duel:)
      end
    end
  end
end
