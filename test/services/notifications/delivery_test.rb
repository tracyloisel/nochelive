require "test_helper"

class Notifications::DeliveryTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues one delivery per subscription and deduplicates repeated calls" do
    with_web_push_enabled do
      duel = street_duels(:pili_vs_carmen)

      assert_difference -> { NotificationDelivery.count }, 1 do
        Notifications::Enqueue.call(
          person: people(:carmen_garcia), kind: "duel_result", subject: duel,
          destination: "/desafio/#{duel.token}", dedupe_token: "new-fixture"
        )
      end
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::Enqueue.call(
          person: people(:carmen_garcia), kind: "duel_result", subject: duel,
          destination: "/desafio/#{duel.token}", dedupe_token: "new-fixture"
        )
      end
      assert_enqueued_jobs 1, only: NotificationDeliveryJob
    end
  end

  test "marks a successful push sent and a second execution is inert" do
    delivery = notification_deliveries(:carmen_duel_result)
    delivery.update!(status: "queued", sent_at: nil)
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled do
      Notifications::Deliver.call(delivery:)
      Notifications::Deliver.call(delivery: delivery.reload)
    end

    assert_equal 1, calls
    assert delivery.reload.sent?
  end

  test "recovers a legacy sending row instead of leaving it stuck" do
    delivery = notification_deliveries(:carmen_duel_result)
    delivery.update!(status: "sending", sent_at: nil)
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert_equal 1, calls
    assert delivery.reload.sent?
  end

  test "cancels work when the category was withdrawn before delivery" do
    delivery = notification_deliveries(:carmen_duel_result)
    delivery.update!(status: "queued", sent_at: nil)
    delivery.person.notification_preference.disable!("challenges")
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert_equal 0, calls
    assert delivery.reload.cancelled?
    assert_equal "no_longer_deliverable", delivery.error_code
  end

  test "revokes expired endpoints without retry" do
    delivery = notification_deliveries(:carmen_duel_result)
    delivery.update!(status: "queued", sent_at: nil)
    response = Struct.new(:body).new("")
    Notifications::Sender.transport = ->(**) { raise WebPush::ExpiredSubscription.new(response, "push.example.test") }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert delivery.reload.failed?
    assert delivery.web_push_subscription.reload.revoked_at
    assert_equal "subscription_expired", delivery.error_code
  end

  test "raises a normalized transient error for 429" do
    delivery = notification_deliveries(:carmen_duel_result)
    delivery.update!(status: "queued", sent_at: nil)
    response = Struct.new(:body).new("")
    Notifications::Sender.transport = ->(**) { raise WebPush::TooManyRequests.new(response, "push.example.test") }

    with_web_push_enabled do
      assert_raises(Notifications::Deliver::TransientError) { Notifications::Deliver.call(delivery:) }
    end
    assert delivery.reload.queued?
    assert_equal "rate_limited", delivery.error_code
  end
end
