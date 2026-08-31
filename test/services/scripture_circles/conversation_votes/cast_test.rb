require "test_helper"

class ScriptureCircles::ConversationVotes::CastTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @voter = people(:carmen_lopez)
    @root = publish(kind: "question", body: "Comment puis-je garder cette parole près de moi ?")
  end

  test "creates changes and removes a member's vote when the same direction is sent again" do
    first = cast(direction: "up")

    assert first.changed
    assert_equal @root, first.conversation_root
    assert_equal "up", first.vote.direction
    assert_equal 1, votes_for_root.count
    assert_equal [ "up" ], votes_for_root.pluck(:direction)

    removed = cast(direction: "up")

    assert removed.changed
    assert_nil removed.vote
    assert_empty votes_for_root
  end

  test "changes an existing direction without creating a second vote" do
    cast(direction: "up")

    result = cast(direction: "down")

    assert result.changed
    assert_equal "down", result.vote.direction
    assert_equal 1, votes_for_root.count
    assert_equal [ "down" ], votes_for_root.pluck(:direction)
  end

  test "rejects self votes invalid directions replies hidden roots cross-ward access and read-only wards" do
    assert_raises ActiveRecord::RecordInvalid do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: @author, conversation_root_id: @root.id, direction: "up"
      )
    end
    assert_raises(ActiveRecord::RecordInvalid) { cast(direction: "sideways") }

    reply = ScriptureCircles::Publish.call(
      person: @voter,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", parent_id: @root.id, body: "Je vais reprendre cette phrase demain." }
    )
    assert_raises ActiveRecord::RecordNotFound do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: @voter, conversation_root_id: reply.id, direction: "up"
      )
    end

    @root.update!(status: "author_deleted", deleted_at: Time.current)
    assert_raises(ActiveRecord::RecordNotFound) { cast(direction: "up") }

    other_ward = extra_ward(132, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    assert_raises ActiveRecord::RecordNotFound do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: outsider, conversation_root_id: @root.id, direction: "up"
      )
    end

    visible_root = publish(kind: "reflection", body: "Une autre réflexion qui reste disponible.")
    @ward.update!(scripture_circle_mode: "read_only")
    assert_raises ScriptureCircles::Access::Disabled do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: @voter, conversation_root_id: visible_root.id, direction: "up"
      )
    end
  end

  test "rejects a vote from a stale requester transferred to another ward during the cast" do
    destination = extra_ward(133, scripture_circle_mode: "active")
    stale_voter = Person.find(@voter.id)
    People::Transfer.call(person: Person.find(@voter.id), ward: destination)

    assert_equal @ward.id, stale_voter.ward_id
    assert_raises(ActiveRecord::RecordNotFound) do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: stale_voter,
        conversation_root_id: @root.id,
        direction: "up",
        device_digest: "conversation-vote-device"
      )
    end

    assert_equal destination.id, @voter.reload.ward_id
    assert_empty votes_for_root
  end

  private

    def publish(kind:, body:)
      ScriptureCircles::Publish.call(
        person: @author,
        reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", body: }
      )
    end

    def cast(direction:)
      ScriptureCircles::ConversationVotes::Cast.call(
        person: @voter,
        conversation_root_id: @root.id,
        direction:,
        device_digest: "conversation-vote-device"
      )
    end

    def votes_for_root
      ScriptureCircleConversationVote.where(conversation_root: @root)
    end
end
