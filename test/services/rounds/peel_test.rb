require "test_helper"

class Rounds::PeelTest < ActiveSupport::TestCase
  setup do
    @night = create_night
    @round = @night.round_runs.find_by!(yaml_round_id: "finale_prophet")
    @round.update!(phase: "intro", layer_index: 0)
  end

  test "abrir peels to layer one and stays intro" do
    pulses = capture_pulses(@night) { Rounds::Open.call(round: @round) }

    assert_equal 1, @round.reload.layer_index
    assert @round.intro?
    assert_not @round.open?
    assert_equal "pan", @round.current_layer["key"]
    assert_equal [ "advance" ], pulses.map { |pulse| pulse&.fetch(:kind, nil) }
  end

  test "fourth peel is salsa without opening" do
    4.times { Rounds::Peel.call(round: @round.reload) }

    assert @round.reload.last_layer?
    assert @round.burger_assembled?
    assert @round.intro?
    assert_not @round.open?
    assert_equal "salsa", @round.current_layer["key"]
    assert_equal "La salsa.", @round.current_layer["text"]
  end

  test "pregunta opens chapel buzzers" do
    peel_to_salsa(@round)
    Rounds::Open.call(round: @round)

    assert @round.reload.open?
    assert @round.accepting_buzzes?
    lucia = add_player(@night, name: "Lucía", team: add_team(@night, name: "Leones"))
    Buzzes::Accept.call(round_run: @round, team: lucia.team, player: lucia)
    assert @round.buzzes.exists?(team: lucia.team)
  end

  test "further peels after salsa are no-ops" do
    peel_to_salsa(@round)
    assert_nothing_raised { Rounds::Peel.call(round: @round) }
    assert_equal 4, @round.reload.layer_index
    assert @round.intro?
  end

  private

    def capture_pulses(_night)
      pulses = []
      original = GameSession.instance_method(:broadcast_state)
      GameSession.define_method(:broadcast_state) { |pulse: nil| pulses << pulse }
      yield
      pulses
    ensure
      GameSession.define_method(:broadcast_state, original)
    end
end
