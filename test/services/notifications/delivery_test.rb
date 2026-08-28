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

  test "editorial lock prevents new jobs and cancels already queued work" do
    duel = street_duels(:pili_vs_carmen)
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled(delivery: false) do
      assert_no_difference -> { NotificationDelivery.count } do
        Notifications::Enqueue.call(
          person: people(:carmen_garcia), kind: "duel_result", subject: duel,
          destination: "/desafio/#{duel.token}", dedupe_token: "editorial-lock"
        )
      end
      assert_no_enqueued_jobs only: NotificationDeliveryJob

      delivery = notification_deliveries(:carmen_duel_result)
      delivery.update!(status: "queued", sent_at: nil)
      Notifications::Deliver.call(delivery:)
      assert delivery.reload.cancelled?
    end

    assert_equal 0, calls
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

  test "cancels a night reminder when the player already joined" do
    night = game_sessions(:elias)
    night.update!(starts_at: 15.minutes.from_now)
    person = people(:carmen_garcia)
    person.notification_preference.enable!("nights")
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push), person:,
      kind: "night_starting_soon", dedupe_key: "joined-night-delivery",
      subject: night, destination: "/s/#{night.code}/name", status: "queued"
    )
    night.players.create!(
      person:, name: "Carmen", role: "participant", location: "room",
      client_token: "delivery-joined", avatar_key: "delfin"
    )
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert_equal 0, calls
    assert delivery.reload.cancelled?
  end

  test "delivers a night reminder only while the lobby is still timely" do
    night = game_sessions(:elias)
    night.update!(starts_at: 15.minutes.from_now)
    person = people(:carmen_garcia)
    person.notification_preference.enable!("nights")
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push), person:,
      kind: "night_starting_soon", dedupe_key: "timely-night-delivery",
      subject: night, destination: "/s/#{night.code}/name", status: "queued"
    )
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert_equal 1, calls
    assert delivery.reload.sent?
  end

  test "cancels a night reminder after the event moves outside its delivery window" do
    night = game_sessions(:elias)
    night.update!(starts_at: 2.hours.from_now)
    person = people(:carmen_garcia)
    person.notification_preference.enable!("nights")
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push), person:,
      kind: "night_starting_soon", dedupe_key: "rescheduled-night-delivery",
      subject: night, destination: "/s/#{night.code}/name", status: "queued"
    )
    calls = 0
    Notifications::Sender.transport = ->(**) { calls += 1 }

    with_web_push_enabled { Notifications::Deliver.call(delivery:) }

    assert_equal 0, calls
    assert delivery.reload.cancelled?
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
