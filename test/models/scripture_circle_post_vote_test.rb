require "test_helper"

class ScriptureCirclePostVoteTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = publish(person: @author, kind: "question", body: "Comment vivre cette parole aujourd’hui ?")
    @reply = publish(person: @author, kind: "reply", parent: @root, body: "Je commence par un geste simple.")
  end

  test "accepts one scored vote from another member on a visible reply" do
    upvote = build_vote(direction: "up")
    downvote = build_vote(direction: "down")

    assert_predicate upvote, :valid?
    assert_equal 1, upvote.score
    assert_predicate downvote, :valid?
    assert_equal(-1, downvote.score)

    upvote.save!
    assert_not build_vote(direction: "down").valid?
  end

  test "rejects root hidden self and cross-ward votes" do
    assert_not build_vote(post: @root).valid?

    @reply.update!(status: "author_deleted", deleted_at: Time.current)
    assert_not build_vote.valid?

    visible_reply = publish(person: @author, kind: "reply", parent: @root, body: "Une autre réponse visible.")
    assert_not build_vote(post: visible_reply, voter: @author).valid?

    other_ward = extra_ward(134, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    assert_not build_vote(post: visible_reply, voter: outsider).valid?
  end

  private

    def publish(person:, kind:, body:, parent: nil)
      ScriptureCircles::Publish.call(
        person:, reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", parent_id: parent&.id, body: }
      )
    end

    def build_vote(post: @reply, voter: @voter, direction: "up")
      ScriptureCirclePostVote.new(
        scripture_circle_post: post,
        ward: @ward,
        voter_person: voter,
        direction:
      )
    end
end
