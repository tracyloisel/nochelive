require "test_helper"

class ScoreApplierTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
    @leones = teams(:leones)
    @casa = teams(:casa)
  end

  test "incorrect is idempotent and breaks the streak" do
    @leones.update!(streak: 2)
    ScoreApplier.incorrect!(@round, @leones)
    ScoreApplier.incorrect!(@round, @leones)
    assert_equal 1, @leones.score_events.where(kind: "incorrect", round_run: @round).count
    assert_equal 0, @leones.reload.streak
  end

  test "fastest buzz bonus when the team buzzed first" do
    Buzz.accept!(round_run: @round, team: @casa, player: players(:daniel))
    ScoreApplier.correct!(@round, @casa)
    assert @casa.score_events.where(kind: "fastest_buzz", round_run: @round).exists?
    assert @casa.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "crown doubles the next correct and a rank-up grants Rey again" do
    @casa.update!(next_correct_doubled: true)
    ScoreApplier.correct!(@round, @casa)
    event = @casa.score_events.find_by!(kind: "correct", round_run: @round)
    assert_equal @round.definition.points * 2, event.points
    @casa.reload
    assert_equal "Explorador", @casa.pending_rank_up
    assert @casa.rey?
  end

  test "Rey is spent when the team does not rise" do
    ScoreEvent.award!(game_session: @night, team: @casa, kind: "adjust", points: 0, xp: 120, reason: "base")
    @casa.reload
    Ranks::Acknowledge.call(team: @casa)
    @casa.update!(next_correct_doubled: true)
    ScoreApplier.correct!(@round, @casa)
    event = @casa.score_events.find_by!(kind: "correct", round_run: @round)
    assert_equal @round.definition.points * 2, event.points
    @casa.reload
    assert_equal "consejero", @casa.rank_key
    assert_not @casa.rey?
  end

  test "presenter adjust creates a ledger row" do
    ScoreApplier.adjust!(@night, @casa, points: 5, reason: "Ajuste")
    assert @casa.score_events.where(kind: "adjust", points: 5).exists?
  end
end
