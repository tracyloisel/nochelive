require "test_helper"

class Quizzes::EnsureHubDuelTest < ActiveSupport::TestCase
  setup do
    @pili = people(:pili)
    @carmen = people(:carmen_garcia)
  end

  test "reuses a named open duel without inventing the missing score" do
    duel = StreetDuel.create!(
      challenger_person: @pili,
      opponent_person: @carmen,
      ward: @pili.ward,
      pack_id: "placas",
      token: "ensure-open-token",
      status: "challenger_done",
      challenger_score: 64,
      expires_at: 7.days.from_now
    )
    result = Quizzes::EnsureHubDuel.call(person: @pili, rival: @carmen)
    assert_equal duel.id, result.duel.id
    assert_equal 64, result.duel.challenger_score
    assert_nil result.duel.opponent_score
    assert_equal @carmen.id, result.rival.id
  end

  test "opens a named duel from a finished pack that is not a rematch" do
    QuizRun.create!(
      device_digest: GameSession.digest_token("ensure-placas"),
      person: @pili,
      pack_id: "placas",
      position: 10,
      score: 47,
      status: "finished",
      opened_at: 1.hour.ago
    )
    result = Quizzes::EnsureHubDuel.call(person: @pili, rival: @carmen)
    assert result.duel.challenger_done?
    assert_equal @carmen.id, result.duel.opponent_person_id
    assert_equal "placas", result.duel.pack_id
    assert_equal 47, result.duel.challenger_score
    assert_nil result.duel.opponent_score
  end

  test "starts an in-progress duel instead of recycling a resolved result" do
    old = street_duels(:pili_vs_carmen)
    old.update!(updated_at: Time.current)

    result = Quizzes::EnsureHubDuel.call(person: @pili, rival: @carmen)

    assert_not_equal old.id, result.duel.id
    assert result.duel.challenger_done?
    assert_equal @pili.id, result.duel.challenger_person_id
    assert_equal @carmen.id, result.duel.opponent_person_id
    assert_not_nil result.duel.challenger_score
    assert_nil result.duel.opponent_score
  end
end
