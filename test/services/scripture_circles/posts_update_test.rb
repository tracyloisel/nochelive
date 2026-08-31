require "test_helper"

class ScriptureCircles::Posts::UpdateTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @peer = people(:carmen_lopez)
    @reflection = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Une parole anonyme au départ." }
    )
    @question = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Une question que je signe au départ." }
    )
  end

  test "author can change a visible question's semantic visibility and legacy input stays safe" do
    anonymous = ScriptureCircles::Posts::Update.call(
      person: @author,
      post_id: @question.id,
      body: @question.body,
      author_visibility: "anonymous_to_ward"
    )

    assert_predicate anonymous, :anonymous?
    assert_equal I18n.t("scripture_reader.circle.anonymous"), anonymous.author_name_for(@peer)
    assert_equal "anonymity_changed", anonymous.latest_revision.change_kind
    assert_equal "anonymous_to_ward", anonymous.latest_revision.author_visibility

    signed_again = ScriptureCircles::Posts::Update.call(
      person: @author, post_id: @question.id, body: anonymous.body, anonymous: false
    )

    assert_predicate signed_again, :named?
    assert_equal @author.display_name, signed_again.author_name_for(@peer)
    assert_equal "anonymity_changed", signed_again.latest_revision.change_kind
    assert_equal "named", signed_again.latest_revision.author_visibility

    safe_legacy_reflection = ScriptureCircles::Posts::Update.call(
      person: @author, post_id: @reflection.id, body: @reflection.body, anonymous: true
    )
    assert_predicate safe_legacy_reflection, :named?

    assert_raises ActiveRecord::RecordInvalid do
      ScriptureCircles::Posts::Update.call(
        person: @author,
        post_id: @reflection.id,
        body: @reflection.body,
        author_visibility: "anonymous_to_ward"
      )
    end
  end

  test "another member cannot change the author's anonymity" do
    assert_raises ActiveRecord::RecordNotFound do
      ScriptureCircles::Posts::Update.call(
        person: @peer, post_id: @question.id, body: @question.body, author_visibility: "named"
      )
    end
  end
end
