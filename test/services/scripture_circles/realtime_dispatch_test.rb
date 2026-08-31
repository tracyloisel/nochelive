require "test_helper"

class ScriptureCircles::RealtimeDispatchTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @member = people(:carmen_lopez)
    @voter = people(:pili)
  end

  test "publishing, editing, and deleting refresh the Circle index" do
    post = assert_circle_refresh do
      ScriptureCircles::Publish.call(
        person: @author,
        reference: "ot/ps/52",
        attributes: { kind: "question", locale: "fr", body: "Puis-je demander de l’aide ici ?" }
      )
    end

    assert_circle_refresh do
      ScriptureCircles::Posts::Update.call(
        person: @author, post_id: post.id, body: "Puis-je demander de l’aide avec confiance ?"
      )
    end

    assert_circle_refresh do
      ScriptureCircles::Posts::Destroy.call(person: @author, post_id: post.id)
    end
  end

  test "moderation visibility changes refresh the Circle index but ballots do not" do
    post = publish_reflection
    reporter_two = Person.create!(ward: @ward, given_name: "Noémie", avatar_key: "colibri", locale: "fr")
    reporter_three = Person.create!(ward: @ward, given_name: "Lucas", avatar_key: "loro", locale: "fr")
    assert_no_circle_refresh do
      ScriptureCircles::Moderations::Report.call(
        person: @member, post_id: post.id, reason_key: "uncharitable"
      )
    end
    assert_no_circle_refresh do
      ScriptureCircles::Moderations::Report.call(
        person: reporter_two, post_id: post.id, reason_key: "uncharitable"
      )
    end
    proposal = assert_circle_refresh do
      ScriptureCircles::Moderations::Report.call(
        person: reporter_three, post_id: post.id, reason_key: "uncharitable"
      ).proposal
    end

    assert_no_circle_refresh do
      ScriptureCircles::Moderations::CastBallot.call(person: @voter, proposal_id: proposal.id, choice: "yes")
    end

    travel 3.days do
      assert_circle_refresh { ScriptureCircles::Moderations::ResolveDue.call }
    end
  end

  test "conversation votes refresh the Circle index so its ranking stays current" do
    post = publish_reflection

    assert_circle_refresh do
      ScriptureCircles::ConversationVotes::Cast.call(
        person: @voter,
        conversation_root_id: post.id,
        direction: "up"
      )
    end
  end

  private

    def publish_reflection
      ScriptureCircles::Publish.call(
        person: @author,
        reference: "ot/ps/52",
        attributes: { kind: "reflection", locale: "fr", body: "Cette parole mérite d’être relue ensemble." }
      )
    end

    def assert_circle_refresh
      result, messages = capture_circle_refreshes { yield }

      assert_equal [ "<turbo-stream action=\"circle_refresh\" target=\"circle_live_feed\"><template></template></turbo-stream>" ], messages
      result
    end

    def assert_no_circle_refresh
      _result, messages = capture_circle_refreshes { yield }

      assert_empty messages
    end

    def capture_circle_refreshes
      result = nil
      messages = capture_broadcasts(stream_name) do
        result = yield
      end
      [ result, messages ]
    end

    def stream_name
      [ @ward.to_gid_param, ScriptureCircles::RamaRefresh::STREAM ].join(":")
    end
end
