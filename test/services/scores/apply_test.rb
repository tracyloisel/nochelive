require "test_helper"

class Scores::ApplyTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
    @leones = teams(:leones)
    @casa = teams(:casa)
  end

  test "incorrect is idempotent, awards nothing, and breaks the streak" do
    @leones.update!(streak: 2)
    Scores::Apply.incorrect!(@round, @leones)
    Scores::Apply.incorrect!(@round, @leones)
    event = @leones.score_events.find_by!(kind: "incorrect", round_run: @round)
    assert_equal 1, @leones.score_events.where(kind: "incorrect", round_run: @round).count
    assert_equal 0, event.points
    assert_equal 0, event.xp
    assert_equal 0, @leones.reload.streak
  end

  test "incorrect strips points from a previous correct" do
    Buzz.accept!(round_run: @round, team: @casa, player: players(:daniel))
    Scores::Apply.correct!(@round, @casa)
    assert_operator @casa.reload.cached_score, :>, 0
    assert @casa.score_events.where(kind: "fastest_buzz", round_run: @round).exists?

    Scores::Apply.incorrect!(@round, @casa)
    @casa.reload
    assert_equal 0, @casa.cached_score
    assert_equal 0, @casa.xp
    assert_not @casa.score_events.where(kind: "correct", round_run: @round).exists?
    assert_not @casa.score_events.where(kind: "fastest_buzz", round_run: @round).exists?
    assert @casa.score_events.where(kind: "incorrect", round_run: @round).exists?
    assert_not @casa.rey?
    assert_nil @casa.pending_rank_up
    assert_nil @casa.ready_chest
  end

  test "correct can override a previous incorrect" do
    Scores::Apply.incorrect!(@round, @casa)
    Scores::Apply.correct!(@round, @casa)
    assert @casa.score_events.where(kind: "correct", round_run: @round).exists?
    assert_not @casa.score_events.where(kind: "incorrect", round_run: @round).exists?
    assert_operator @casa.reload.cached_score, :>, 0
  end

  test "fastest buzz bonus when the team buzzed first" do
    Buzz.accept!(round_run: @round, team: @casa, player: players(:daniel))
    Scores::Apply.correct!(@round, @casa)
    assert @casa.score_events.where(kind: "fastest_buzz", round_run: @round).exists?
    assert @casa.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "crown doubles the next correct and a rank-up grants Rey again" do
    @casa.update!(next_correct_doubled: true)
    Scores::Apply.correct!(@round, @casa)
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
    Scores::Apply.correct!(@round, @casa)
    event = @casa.score_events.find_by!(kind: "correct", round_run: @round)
    assert_equal @round.definition.points * 2, event.points
    @casa.reload
    assert_equal "consejero", @casa.rank_key
    assert_not @casa.rey?
  end

  test "presenter adjust creates a ledger row" do
    Scores::Apply.adjust!(@night, @casa, points: 5, reason: "Ajuste")
    assert @casa.score_events.where(kind: "adjust", points: 5).exists?
  end
end
