require "test_helper"

class BuzzesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
  end

  test "accepts a buzz" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    assert_difference -> { Buzz.where(round_run: @round).count }, 1 do
      post night_round_run_buzz_path(@night.code, @round)
    end
    assert_redirected_to night_play_path(@night.code)
  end

  test "closed round still redirects" do
    @round.lock!
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_buzz_path(@night.code, @round)
    assert_redirected_to night_play_path(@night.code)
  end

  test "stores milliseconds since the buzzer opened" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    @round.update!(opened_at: 0.28.seconds.ago)
    post night_round_run_buzz_path(@night.code, @round)
    buzz = Buzz.find_by!(round_run: @round, team: teams(:leones))
    assert_in_delta 280, buzz.latency_ms, 80
  end

  test "requires a team" do
    sign_in_as_participant(@night, name: "Sofía")
    post night_round_run_buzz_path(@night.code, @round)
    assert_redirected_to night_play_path(@night.code)
  end
end
