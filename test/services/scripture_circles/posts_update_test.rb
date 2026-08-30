require "test_helper"

class ScriptureCircles::Posts::UpdateTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @peer = people(:carmen_lopez)
    @post = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Une parole anonyme au départ." }
    )
  end

  test "author can sign or anonymize their visible post while editing it" do
    signed = ScriptureCircles::Posts::Update.call(
      person: @author, post_id: @post.id, body: @post.body, anonymous: false
    )

    assert_not signed.anonymous?
    assert_equal @author.display_name, signed.author_name_for(@peer)
    assert_equal "anonymity_changed", signed.latest_revision.change_kind
    assert_not signed.latest_revision.anonymous?

    anonymous_again = ScriptureCircles::Posts::Update.call(
      person: @author, post_id: @post.id, body: signed.body, anonymous: true
    )

    assert_predicate anonymous_again, :anonymous?
    assert_equal I18n.t("scripture_reader.circle.anonymous"), anonymous_again.author_name_for(@peer)
    assert_equal "anonymity_changed", anonymous_again.latest_revision.change_kind
    assert_predicate anonymous_again.latest_revision, :anonymous?
  end

  test "another member cannot change the author's anonymity" do
    assert_raises ActiveRecord::RecordNotFound do
      ScriptureCircles::Posts::Update.call(
        person: @peer, post_id: @post.id, body: @post.body, anonymous: false
      )
    end
  end
end
