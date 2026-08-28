require "test_helper"

class Quizzes::ChallengeNotifyTest < ActiveSupport::TestCase
  test "broadcasts when the named opponent is live" do
    carmen = people(:carmen_garcia)
    person_devices(:carmen_phone).update!(last_seen_at: Time.current)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "notify-live-token",
      status: "challenger_done",
      challenger_score: 61,
      expires_at: 7.days.from_now
    )
    assert_equal 1, capture_replace_broadcasts { Quizzes::ChallengeNotify.call(duel:) }
  end

  test "renders the ping partial for a live opponent" do
    carmen = people(:carmen_garcia)
    person_devices(:carmen_phone).update!(last_seen_at: Time.current)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "notify-render-token",
      status: "challenger_done",
      challenger_score: 61,
      expires_at: 7.days.from_now
    )
    assert_nothing_raised { Quizzes::ChallengeNotify.call(duel:) }
  end

  test "stays quiet when the opponent is not live" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "notify-quiet-token",
      status: "challenger_done",
      challenger_score: 61,
      expires_at: 7.days.from_now
    )
    assert_equal 0, capture_replace_broadcasts { Quizzes::ChallengeNotify.call(duel:) }
  end

  test "queues one push for an offline opponent and does not broadcast" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili), opponent_person: carmen,
      ward: wards(:demo), pack_id: "placas", token: "notify-push-token",
      status: "challenger_done", challenger_score: 61, expires_at: 7.days.from_now
    )

    with_web_push_enabled do
      assert_difference -> { NotificationDelivery.where(kind: "duel_invitation").count }, 1 do
        assert_equal 0, capture_replace_broadcasts { Quizzes::ChallengeNotify.call(duel:) }
      end
    end
  end

  test "never queues a push while the opponent is live" do
    carmen = people(:carmen_garcia)
    person_devices(:carmen_phone).update!(last_seen_at: Time.current)
    duel = StreetDuel.create!(
      challenger_person: people(:pili), opponent_person: carmen,
      ward: wards(:demo), pack_id: "placas", token: "notify-live-no-push",
      status: "challenger_done", challenger_score: 61, expires_at: 7.days.from_now
    )

    with_web_push_enabled do
      assert_no_difference -> { NotificationDelivery.count } do
        assert_equal 1, capture_replace_broadcasts { Quizzes::ChallengeNotify.call(duel:) }
      end
    end
  end

  test "skips an anonymous share" do
    assert_equal 0, capture_replace_broadcasts { Quizzes::ChallengeNotify.call(duel: street_duels(:pending_challenge)) }
  end

  private

    def capture_replace_broadcasts
      count = 0
      original = Turbo::StreamsChannel.method(:broadcast_replace_to)
      Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| count += 1 }
      yield
      count
    ensure
      Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to, original)
    end
end
