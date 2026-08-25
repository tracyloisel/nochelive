require "test_helper"

class PoseHoldTest < ActiveSupport::TestCase
  test "a short hold does not score and a full hold does once" do
    night = create_night
    player = add_player(night, name: "Daniel", location: "remote")
    team = player.team
    round = night.round_runs.find_by!(yaml_round_id: "statue_david")
    round.intro!
    round.open!

    short = PoseHold.complete!(round_run: round, team: team, player: player, held_ms: 1200)
    assert_not short.finished?
    assert_equal 0, team.score_events.where(kind: "rapid_tap").count

    done = PoseHold.complete!(round_run: round, team: team, player: player, held_ms: 8500)
    assert done.finished?
    assert_equal 1, team.reload.score_events.where(reason: "scores.statue").count

    PoseHold.complete!(round_run: round, team: team, player: player, held_ms: 9000)
    assert_equal 1, team.reload.score_events.where(reason: "scores.statue").count
  end
end
