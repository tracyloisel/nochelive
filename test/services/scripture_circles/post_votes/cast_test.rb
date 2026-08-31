require "test_helper"

class ScriptureCircles::PostVotes::CastTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = publish(person: @author, kind: "question", body: "Comment recevoir cette parole ?")
    @reply = publish(person: @author, kind: "reply", parent: @root, body: "Je la relis lentement.")
  end

  test "creates changes and toggles a reply vote" do
    first = cast("up")

    assert_equal @reply, first.post
    assert_equal "up", first.vote.direction
    assert_equal 1, @reply.reload.post_vote_score

    changed = cast("down")
    assert_equal "down", changed.vote.direction
    assert_equal(-1, @reply.reload.post_vote_score)

    removed = cast("down")
    assert_nil removed.vote
    assert_equal 0, @reply.reload.post_vote_score
  end

  test "rejects roots self votes hidden replies cross-ward access and read-only wards" do
    assert_raises(ActiveRecord::RecordNotFound) { cast("up", post: @root) }
    assert_raises(ActiveRecord::RecordInvalid) { cast("up", person: @author) }

    @reply.update!(status: "author_deleted", deleted_at: Time.current)
    assert_raises(ActiveRecord::RecordNotFound) { cast("up") }

    visible_reply = publish(person: @author, kind: "reply", parent: @root, body: "Une réponse encore visible.")
    other_ward = extra_ward(135, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    assert_raises(ActiveRecord::RecordNotFound) { cast("up", post: visible_reply, person: outsider) }

    @ward.update!(scripture_circle_mode: "read_only")
    assert_raises(ScriptureCircles::Access::Disabled) { cast("up", post: visible_reply) }
  end

  private

    def publish(person:, kind:, body:, parent: nil)
      ScriptureCircles::Publish.call(
        person:, reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", parent_id: parent&.id, body: }
      )
    end

    def cast(direction, post: @reply, person: @voter)
      ScriptureCircles::PostVotes::Cast.call(
        person:, post_id: post.id, direction:, device_digest: "post-vote-device"
      )
    end
end
