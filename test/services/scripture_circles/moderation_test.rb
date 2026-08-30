require "test_helper"

class ScriptureCircles::ModerationTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @proposer = people(:carmen_lopez)
    @voter = people(:pili)
    @post = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Ce verset m’aide à choisir la vérité." }
    )
  end

  test "ward isolation applies to reads publications proposals and ballots" do
    other_ward = extra_ward(32, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")

    assert_raises(ActiveRecord::RecordNotFound) { ScriptureCircles::Access.new(person: outsider).post!(@post.id) }
    assert_raises(ActiveRecord::RecordNotFound) do
      ScriptureCircles::Moderations::Propose.call(
        person: outsider, post_id: @post.id, reason_key: "off_topic"
      )
    end
  end

  test "moderation lasts at least two days and exposes live vote changes" do
    proposal = propose

    assert_equal 2.days, proposal.ends_at - proposal.starts_at
    ballot = ScriptureCircles::Moderations::CastBallot.call(person: @voter, proposal_id: proposal.id, choice: "yes")
    assert_equal [ 1, 0 ], [ proposal.reload.yes_count, proposal.no_count ]

    ScriptureCircles::Moderations::CastBallot.call(person: @voter, proposal_id: proposal.id, choice: "no")

    assert_equal [ 0, 1 ], [ proposal.reload.yes_count, proposal.no_count ]
    assert_equal 2, ballot.scripture_circle_moderation_ballot_revisions.count
    assert_equal %w[yes no], ballot.scripture_circle_moderation_ballot_revisions.order(:created_at, :id).pluck(:new_choice)
  end

  test "resolution censors a majority with quorum and is idempotent" do
    proposal = propose
    fourth = Person.create!(ward: @ward, given_name: "David", avatar_key: "delfin", locale: "fr")
    ScriptureCircles::Moderations::CastBallot.call(person: @author, proposal_id: proposal.id, choice: "yes")
    ScriptureCircles::Moderations::CastBallot.call(person: @voter, proposal_id: proposal.id, choice: "yes")
    ScriptureCircles::Moderations::CastBallot.call(person: fourth, proposal_id: proposal.id, choice: "no")

    travel 3.days do
      assert_equal [ proposal.id ], ScriptureCircles::Moderations::ResolveDue.call.map(&:id)
      assert_empty ScriptureCircles::Moderations::ResolveDue.call
    end

    assert_equal "censored", proposal.reload.status
    assert_equal "community_censored", @post.reload.status
    assert_equal 1, proposal.scripture_circle_moderation_events.where(event_type: "resolved").count
    assert proposal.result_digest.present?
  end

  test "tie or insufficient participation keeps the post" do
    proposal = propose
    ScriptureCircles::Moderations::CastBallot.call(person: @author, proposal_id: proposal.id, choice: "yes")
    ScriptureCircles::Moderations::CastBallot.call(person: @voter, proposal_id: proposal.id, choice: "no")

    travel 3.days do
      ScriptureCircles::Moderations::ResolveDue.call
    end

    assert_equal "kept", proposal.reload.status
    assert_equal "visible", @post.reload.status
  end

  test "author may edit and delete while deletion cancels an open vote" do
    ScriptureCircles::Posts::Update.call(person: @author, post_id: @post.id, body: "Une pensée plus précise.")
    assert_equal "Une pensée plus précise.", @post.reload.body

    proposal = propose
    ScriptureCircles::Posts::Destroy.call(person: @author, post_id: @post.id)

    assert_equal "author_deleted", @post.reload.status
    assert_equal "canceled_by_author", proposal.reload.status
    assert_equal "canceled_by_author", proposal.scripture_circle_moderation_events.last.event_type
  end

  private

    def propose
      ScriptureCircles::Moderations::Propose.call(
        person: @proposer, post_id: @post.id, reason_key: "uncharitable"
      )
    end
end
