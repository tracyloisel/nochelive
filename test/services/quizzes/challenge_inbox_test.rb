require "test_helper"

class Quizzes::ChallengeInboxTest < ActiveSupport::TestCase
  test "incoming is the named opponent's open duel" do
    carmen = people(:carmen_garcia)
    duel = StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "coronas",
      token: "inbox-incoming-token",
      status: "challenger_done",
      challenger_score: 70,
      expires_at: 7.days.from_now
    )
    inbox = Quizzes::ChallengeInbox.call(person: carmen)
    assert_equal [ duel.id ], inbox.incoming.map { |item| item.duel.id }
    assert_equal :accept, inbox.incoming.first.phase
    assert_equal people(:pili), inbox.incoming.first.other
  end

  test "waiting is the challenger's open duel" do
    inbox = Quizzes::ChallengeInbox.call(person: people(:pili))
    waiting_ids = inbox.waiting.map { |item| item.duel.id }
    assert_includes waiting_ids, street_duels(:pending_challenge).id
    assert_equal :waiting, inbox.waiting.find { |item| item.duel.id == street_duels(:pending_challenge).id }.phase
    assert_equal :link, inbox.waiting.find { |item| item.duel.id == street_duels(:pending_challenge).id }.waiting_for
  end

  test "actionable count is incoming duels waiting on you" do
    carmen = people(:carmen_garcia)
    assert_equal 0, Quizzes::ChallengeInbox.actionable_count(person: carmen)
    StreetDuel.create!(
      challenger_person: people(:pili),
      opponent_person: carmen,
      ward: wards(:demo),
      pack_id: "coronas",
      token: "inbox-count-token",
      status: "challenger_done",
      challenger_score: 70,
      expires_at: 7.days.from_now
    )
    assert_equal 1, Quizzes::ChallengeInbox.actionable_count(person: carmen)
  end

  test "recent lists a resolved duel from the last two weeks" do
    inbox = Quizzes::ChallengeInbox.call(person: people(:pili))
    recent_ids = inbox.recent.map { |item| item.duel.id }
    assert_includes recent_ids, street_duels(:pili_vs_carmen).id
    assert_equal :result, inbox.recent.find { |item| item.duel.id == street_duels(:pili_vs_carmen).id }.phase
  end
end
