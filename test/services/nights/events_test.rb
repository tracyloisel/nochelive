require "test_helper"

class Nights::EventsTest < ActiveSupport::TestCase
  test "one answer can narrate its score streak and new leader in one broadcast" do
    night = game_sessions(:david)
    player = players(:lucia)
    run = QuizRun.create!(device_digest: "event-answer", pack_id: "coronas", opened_at: Time.current, score: 10, game_session: night, player:, team: player.team, live_sequence_position: 1)
    answer = run.quiz_answers.create!(
      device_digest: run.device_digest,
      pack_id: run.pack_id,
      question_id: run.question.id,
      correct: true,
      points_awarded: 10,
      streak_after: 3
    )

    Nights::Events.after_answer(run:, answer:, previous_score: 0)

    assert_equal %w[correct streak lead_change], night.live_events.order(:id).last(3).map(&:kind)
    assert_equal 3, night.live_events.find_by!(kind: "streak").payload.fetch("streak")
  end
end
