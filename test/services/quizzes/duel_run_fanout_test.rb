require "test_helper"

class Quizzes::DuelRunFanoutTest < ActiveSupport::TestCase
  test "one raw score updates every eligible active duel across different paths" do
    pili = people(:pili)
    scored_invitation = DuelInvitation.create!(
      challenger_person: people(:carmen_garcia), recipient_person: pili,
      challenger_run: quiz_runs(:carmen_milagros), challenger_score: 120,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    open_invitation = DuelInvitation.create!(
      challenger_person: people(:carmen_lopez), recipient_person: pili,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    scored_duel = Quizzes::DuelInvitationClaim.call(invitation: scored_invitation, person: pili).duel
    open_duel = Quizzes::DuelInvitationClaim.call(invitation: open_invitation, person: pili).duel
    run = QuizRun.create!(
      device_digest: "pili-fanout", person: pili, pack_id: "placas", position: 10,
      score: 104, status: "finished", opened_at: 1.minute.from_now
    )

    impacts = Quizzes::DuelRunFanout.call(run:)

    assert_equal [ open_duel.id, scored_duel.id ].sort, impacts.map { |impact| impact.duel.id }.sort
    assert scored_duel.reload.resolved?
    assert_equal 104, scored_duel.opponent_score
    assert open_duel.reload.one_scored?
    assert_equal 104, open_duel.opponent_score
  end

  test "a run opened before acceptance cannot be retroactively attached" do
    invitation = duel_invitations(:named_pili_invitation)
    run = QuizRun.create!(
      device_digest: "old-run", person: people(:carmen_garcia), pack_id: "placas",
      position: 10, score: 70, status: "finished", opened_at: 1.hour.ago
    )
    duel = Quizzes::DuelInvitationClaim.call(invitation:, person: people(:carmen_garcia)).duel

    assert_empty Quizzes::DuelRunFanout.call(run:)
    assert_nil duel.reload.opponent_run
  end
end
