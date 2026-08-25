require "test_helper"

class Buzzes::AcceptTest < ActiveSupport::TestCase
  setup do
    @night = create_night
    @round = @night.round_runs.first
    @round.intro!
    @round.open!
    @team = add_team(@night, name: "Leones")
    @player = add_player(@night, name: "Marta", team: @team)
  end

  test "records milliseconds since the presenter opened the buzzer" do
    @round.update!(opened_at: 0.342.seconds.ago)
    buzz = Buzzes::Accept.call(round_run: @round, team: @team, player: @player)
    assert_in_delta 342, buzz.latency_ms, 40
    assert_equal 1, buzz.position
  end

  test "idempotent rematch keeps the first latency" do
    @round.update!(opened_at: 0.2.seconds.ago)
    one = Buzzes::Accept.call(round_run: @round, team: @team, player: @player)
    travel 1.second
    two = Buzzes::Accept.call(round_run: @round, team: @team, player: @player)
    assert_equal one.id, two.id
    assert_equal one.latency_ms, two.latency_ms
  end

  test "rejects a remote player" do
    remote = add_player(@night, name: "Daniel", location: "remote")
    assert_raises(RuntimeError) do
      Buzzes::Accept.call(round_run: @round, team: remote.team, player: remote)
    end
    assert_not Buzz.exists?(round_run: @round, player: remote)
  end
end
