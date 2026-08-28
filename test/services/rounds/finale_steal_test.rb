require "test_helper"

class Rounds::FinaleStealTest < ActiveSupport::TestCase
  setup do
    @night = create_night
    @round = @night.round_runs.find_by!(yaml_round_id: "finale_prophet")
    peel_to_salsa(@round)
    Rounds::Open.call(round: @round)
  end

  test "casa cannot answer until the chapel misses or locks empty" do
    leones = add_team(@night, name: "Leones")
    lucia = add_player(@night, name: "Lucía", team: leones)
    daniel = add_player(@night, name: "Daniel", location: "remote")
    casa = daniel.team

    error = assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: casa, player: daniel, body: "double")
    end
    assert_match(/Esperad el slam/, error.message)

    Buzzes::Accept.call(round_run: @round, team: leones, player: lucia)
    Answers::Submit.call(round: @round, team: leones, player: lucia, body: "chariot")
    assert @round.reload.finale_steal_open?

    Answers::Submit.call(round: @round.reload, team: casa, player: daniel, body: "double")
    Answers::GradeChoices.call(round: @round)
    assert casa.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "empty lock opens the steal" do
    add_team(@night, name: "Leones").tap { |team| add_player(@night, name: "Lucía", team: team) }
    daniel = add_player(@night, name: "Daniel", location: "remote")
    Rounds::Lock.call(round: @round)
    assert @round.reload.finale_steal_open?
    Answers::Submit.call(round: @round, team: daniel.team, player: daniel, body: "double")
    Answers::GradeChoices.call(round: @round)
    assert daniel.team.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "casa plays at once when nobody is in the chapel" do
    daniel = add_player(@night, name: "Daniel", location: "remote")
    assert @round.finale_steal_open?
    Answers::Submit.call(round: @round, team: daniel.team, player: daniel, body: "double")
    Answers::GradeChoices.call(round: @round)
    assert daniel.team.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "a chapel just closes the steal" do
    leones = add_team(@night, name: "Leones")
    lucia = add_player(@night, name: "Lucía", team: leones)
    daniel = add_player(@night, name: "Daniel", location: "remote")
    Buzzes::Accept.call(round_run: @round, team: leones, player: lucia)
    Answers::Submit.call(round: @round, team: leones, player: lucia, body: "double")
    assert_not @round.reload.finale_steal_open?
    assert_raises(RuntimeError) do
      Answers::Submit.call(round: @round, team: daniel.team, player: daniel, body: "double")
    end
  end
end
