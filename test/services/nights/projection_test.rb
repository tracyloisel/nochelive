require "test_helper"

class Nights::ProjectionTest < ActiveSupport::TestCase
  test "registration projection only exposes the lightweight pre-live count" do
    projection = Nights::Projection.registration(night: game_sessions(:elias))

    assert_equal game_sessions(:elias).players.count, projection.registered
    assert_empty projection.teams
    assert_empty projection.questions
    assert_empty projection.events
  end

  test "team score is the raw sum of its live quiz run scores" do
    night = game_sessions(:david)
    player = players(:lucia)
    QuizRun.create!(device_digest: "live-a", pack_id: "coronas", opened_at: Time.current, score: 37, game_session: night, player:, team: player.team, live_sequence_position: 1)

    row = Nights::Projection.call(night:).teams.find { |team| team.id == player.team.id }
    assert_equal 37, row.score
  end

  test "question progress only counts players who reached its quiz" do
    night = game_sessions(:david)
    player = players(:lucia)
    run = QuizRun.create!(device_digest: "live-progress", pack_id: "coronas", opened_at: Time.current, game_session: night, player:, team: player.team, live_sequence_position: 1)
    question = run.pack.questions.first
    QuizAnswer.create!(quiz_run: run, device_digest: run.device_digest, pack_id: run.pack_id, question_id: question.id, choice_key: question.correct_choice, correct: true)

    row = Nights::Projection.call(night:).questions.first

    assert_equal "Q1", row.label
    assert_equal 1, row.answered
    assert_equal 1, row.eligible
    assert_equal 100, row.percent
  end
end
