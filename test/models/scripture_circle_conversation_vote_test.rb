require "test_helper"

class ScriptureCircleConversationVoteTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = publish(kind: "question", body: "Comment cette parole peut-elle guider ma semaine ?")
  end

  test "accepts one up or down vote from another member and exposes its score" do
    upvote = build_vote(direction: "up")
    downvote = build_vote(direction: "down")

    assert_predicate upvote, :valid?
    assert_equal 1, upvote.score
    assert_predicate downvote, :valid?
    assert_equal(-1, downvote.score)
  end

  test "enforces one vote per member and conversation root" do
    build_vote(direction: "up").save!
    duplicate = build_vote(direction: "down")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.details[:voter_person_id].map { |detail| detail[:error] }, :taken
  end

  test "rejects an invalid direction a self vote and a voter from another ward" do
    invalid_direction = build_vote(direction: "sideways")
    self_vote = build_vote(voter: @author)
    other_ward = extra_ward(131, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    cross_ward_vote = build_vote(voter: outsider)

    assert_not invalid_direction.valid?
    assert_includes invalid_direction.errors.details[:direction].map { |detail| detail[:error] }, :inclusion
    assert_not self_vote.valid?
    assert_includes self_vote.errors.details[:voter_person].map { |detail| detail[:error] }, :invalid
    assert_not cross_ward_vote.valid?
    assert_includes cross_ward_vote.errors.details[:voter_person].map { |detail| detail[:error] }, :invalid
  end

  test "accepts only visible question or reflection roots from the same ward" do
    reply = ScriptureCircles::Publish.call(
      person: @voter,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", parent_id: @root.id, body: "Je relis aussi le verset précédent." }
    )
    hidden_root = publish(kind: "reflection", body: "Cette pensée ne doit plus être classée.")
    hidden_root.update!(status: "author_deleted", deleted_at: Time.current)

    reply_vote = build_vote(conversation_root: reply)
    hidden_vote = build_vote(conversation_root: hidden_root)

    assert_not reply_vote.valid?
    assert_includes reply_vote.errors.details[:conversation_root].map { |detail| detail[:error] }, :invalid
    assert_not hidden_vote.valid?
    assert_includes hidden_vote.errors.details[:conversation_root].map { |detail| detail[:error] }, :invalid
  end

  private

    def publish(kind:, body:)
      ScriptureCircles::Publish.call(
        person: @author,
        reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", body: }
      )
    end

    def build_vote(conversation_root: @root, voter: @voter, direction: "up")
      ScriptureCircleConversationVote.new(
        conversation_root:,
        ward: @ward,
        voter_person: voter,
        direction:
      )
    end
end
