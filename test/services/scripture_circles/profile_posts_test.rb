require "test_helper"

class ScriptureCircles::ProfilePostsTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @viewer = people(:carmen_lopez)
  end

  test "uses semantic visibility for same-ward profile readers while preserving the author's private view" do
    named = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette réflexion porte mon prénom." }
    )
    anonymous = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: {
        kind: "question", locale: "fr", body: "Cette question est anonyme pour la rama.",
        author_visibility: "anonymous_to_ward"
      }
    )
    archived = ScriptureCircles::Publish.call(
      person: @author,
      reference: "bofm/alma/32",
      attributes: { kind: "reflection", locale: "fr", body: "Ce message se trouve ensuite dans un fil archivé." }
    )
    archived.scripture_circle_thread.update!(status: "archived")

    visitor_result = ScriptureCircles::ProfilePosts.call(
      viewer_person: @viewer,
      profile_person: @author
    )
    owner_result = ScriptureCircles::ProfilePosts.call(
      viewer_person: @author,
      profile_person: @author
    )

    assert_equal [ named.id ], visitor_result.posts.map(&:id)
    assert_not visitor_result.owner_view
    assert_equal [ anonymous.id, named.id ], owner_result.posts.map(&:id)
    assert owner_result.owner_view
  end
end
