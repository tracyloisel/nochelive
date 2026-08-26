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
