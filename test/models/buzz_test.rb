require "test_helper"

class BuzzTest < ActiveSupport::TestCase
  def setup
    @night = create_night
    @round = @night.round_runs.first
    @round.intro!
    @round.open!
    @team_a = add_team(@night, name: "Leones")
    @team_b = add_team(@night, name: "Profetas", emblem: "fuego")
    @player_a = add_player(@night, name: "Marta", team: @team_a)
    @player_b = add_player(@night, name: "Carlos", team: @team_b)
  end

  test "allocates unique positions and a single first place" do
    first = Buzz.accept!(round_run: @round, team: @team_a, player: @player_a)
    second = Buzz.accept!(round_run: @round, team: @team_b, player: @player_b)
    assert_equal 1, first.position
    assert_equal 2, second.position
  end

  test "second tap from the same team is idempotent" do
    one = Buzz.accept!(round_run: @round, team: @team_a, player: @player_a)
    two = Buzz.accept!(round_run: @round, team: @team_a, player: @player_a)
    assert_equal one.id, two.id
    assert_equal 1, Buzz.where(round_run: @round, team: @team_a).count
  end

  test "rejects buzz when the round is closed" do
    @round.lock!
    assert_raises(RuntimeError) do
      Buzz.accept!(round_run: @round, team: @team_a, player: @player_a)
    end
  end

  test "concurrent buzzes produce unique positions and one first" do
    teams = 5.times.map { |i| add_team(@night, name: "T#{i}", emblem: Team::EMBLEMS.keys[i % 6]) }
    players = teams.map { |team| add_player(@night, name: "P#{team.id}", team: team) }

    go = false
    threads = teams.zip(players).map do |team, player|
      Thread.new do
        true until go
        ApplicationRecord.connection_pool.with_connection do
          Buzz.accept!(round_run: @round, team: team, player: player)
        end
      end
    end

    go = true
    threads.each(&:join)

    positions = Buzz.where(round_run: @round).order(:position).pluck(:position)
    assert_equal [ 1, 2, 3, 4, 5 ], positions
    assert_equal 1, positions.count(1)
    assert_equal 5, Buzz.where(round_run: @round).select(:team_id).distinct.count
  end
end
