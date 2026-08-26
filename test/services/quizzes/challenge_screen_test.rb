require "test_helper"

class Quizzes::ChallengeScreenTest < ActiveSupport::TestCase
  test "guest with a token is invited to accept" do
    duel = street_duels(:pending_challenge)
    screen = Quizzes::ChallengeScreen.call(token: duel.token)
    assert_equal :guest, screen.role
    assert_equal :accept, screen.phase
  end

  test "challenger waits after posting a score" do
    duel = street_duels(:pending_challenge)
    duel.update!(status: "challenger_done", challenger_score: 70)
    screen = Quizzes::ChallengeScreen.call(person: people(:pili))
    assert_equal :challenger, screen.role
    assert_equal :waiting, screen.phase
    assert_equal :link, screen.waiting_for
  end

  test "incoming accept beats an older waiting duel on the hub" do
    street_duels(:pending_challenge).update!(status: "challenger_done", challenger_score: 70, updated_at: 2.days.ago)
    incoming = StreetDuel.create!(
      challenger_person: people(:carmen_garcia),
      opponent_person: people(:pili),
      ward: wards(:demo),
      pack_id: "placas",
      token: "hub-priority-token",
      status: "challenger_done",
      challenger_score: 88,
      expires_at: 7.days.from_now
    )
    screen = Quizzes::ChallengeScreen.call(person: people(:pili))
    assert_equal incoming.id, screen.duel.id
    assert_equal :accept, screen.phase
  end

  test "named challenger waits for the opponent to accept" do
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: people(:carmen_garcia),
      ward: wards(:demo),
      pack_id: "coronas",
      token: "named-wait-token",
      status: "challenger_done",
      challenger_score: 64,
      expires_at: 7.days.from_now
    )
    screen = Quizzes::ChallengeScreen.call(duel:, person: people(:pili))
    assert_equal :waiting, screen.phase
    assert_equal :accept, screen.waiting_for
  end

  test "pending duels stay off the hub until a score is on the table" do
    assert_nil Quizzes::ChallengeScreen.call(person: people(:pili))
  end

  test "invitee sees accept and a third person sees taken" do
    duel = street_duels(:pending_challenge)
    invite = Quizzes::ChallengeScreen.call(duel:, person: people(:carmen_garcia))
    assert_equal :invitee, invite.role
    assert_equal :accept, invite.phase

    busy = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: people(:carmen_garcia),
      ward: wards(:demo),
      pack_id: "placas",
      token: "taken-challenge-token",
      status: "challenger_done",
      challenger_score: 70,
      expires_at: 7.days.from_now
    )
    taken = Quizzes::ChallengeScreen.call(duel: busy, person: people(:carmen_lopez))
    assert_equal :other, taken.role
    assert_equal :taken, taken.phase
  end

  test "named opponent without a run is asked to accept" do
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: people(:carmen_garcia),
      ward: wards(:demo),
      pack_id: "coronas",
      token: "named-accept-token",
      status: "challenger_done",
      challenger_score: 64,
      expires_at: 7.days.from_now
    )
    screen = Quizzes::ChallengeScreen.call(duel:, person: people(:carmen_garcia))
    assert_equal :opponent, screen.role
    assert_equal :accept, screen.phase
  end

  test "resolved duel is a result for both players" do
    duel = street_duels(:pili_vs_carmen)
    duel.update!(status: "resolved")
    screen = Quizzes::ChallengeScreen.call(person: people(:pili), duel:)
    assert_equal :result, screen.phase
  end

  test "declined duel is taken" do
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: people(:carmen_garcia),
      ward: wards(:demo),
      pack_id: "placas",
      token: "screen-declined-token",
      status: "declined",
      challenger_score: 40,
      expires_at: 7.days.from_now
    )
    screen = Quizzes::ChallengeScreen.call(duel:, person: people(:carmen_garcia))
    assert_equal :taken, screen.phase
  end
end
