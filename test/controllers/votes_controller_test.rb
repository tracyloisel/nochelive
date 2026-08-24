require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "cast a vote for another team" do
    Ballot.delete_all
    round = round_runs(:vote_solomon)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_vote_path(@night.code, round), params: { team_id: teams(:casa).id }
    assert_redirected_to night_play_path(@night.code)
    assert Ballot.exists?(round_run: round, choice_team: teams(:casa))
  end

  test "own team vote redirects" do
    Ballot.delete_all
    round = round_runs(:vote_solomon)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_vote_path(@night.code, round), params: { team_id: teams(:leones).id }
    assert_redirected_to night_play_path(@night.code)
    assert_not Ballot.exists?(round_run: round, player: Player.find_by(name: "Sofía"))
  end
end
