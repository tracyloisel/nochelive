require "test_helper"

class Quizzes::ChallengeDeclineTest < ActiveSupport::TestCase
  test "named opponent can decline" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "decline-service-token",
      status: "challenger_done",
      challenger_score: 50,
      expires_at: 7.days.from_now
    )
    Quizzes::ChallengeDecline.call(duel:, opponent_person: carmen)
    assert duel.reload.declined?
  end

  test "challenger cannot decline their own invite" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "decline-self-token",
      status: "challenger_done",
      challenger_score: 50,
      expires_at: 7.days.from_now
    )
    assert_raises(Quizzes::ChallengeDecline::Taken) do
      Quizzes::ChallengeDecline.call(duel:, opponent_person: people(:pili))
    end
    assert_not duel.reload.declined?
  end

  test "rejects a second person" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "placas",
      token: "decline-other-token",
      status: "challenger_done",
      challenger_score: 50,
      expires_at: 7.days.from_now
    )
    assert_raises(Quizzes::ChallengeDecline::Taken) do
      Quizzes::ChallengeDecline.call(duel:, opponent_person: people(:carmen_lopez))
    end
  end
end
