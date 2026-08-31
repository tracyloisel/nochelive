require "test_helper"

class ScriptureCircles::Posts::DestroyTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @post = ScriptureCircles::Publish.call(
      person: @author,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Puis-je supprimer ma propre question ?" }
    )
  end

  test "requires active Circle access before an author can delete" do
    @ward.update!(scripture_circle_mode: "read_only")
    assert_raises ScriptureCircles::Access::Disabled do
      ScriptureCircles::Posts::Destroy.call(person: @author, post_id: @post.id)
    end
    assert_equal "visible", @post.reload.status

    @ward.update!(scripture_circle_mode: "disabled")
    assert_raises ScriptureCircles::Access::Disabled do
      ScriptureCircles::Posts::Destroy.call(person: @author, post_id: @post.id)
    end
    assert_equal "visible", @post.reload.status
  end

  test "cannot delete a post from another ward even with its id" do
    other_ward = extra_ward(72, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")

    assert_raises ActiveRecord::RecordNotFound do
      ScriptureCircles::Posts::Destroy.call(person: outsider, post_id: @post.id)
    end
    assert_equal "visible", @post.reload.status
  end
end
