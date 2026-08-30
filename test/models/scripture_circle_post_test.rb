require "test_helper"

class ScriptureCirclePostTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @person = people(:carmen_garcia)
    @thread = @ward.scripture_circle_threads.create!(reference: "ot/ps/52")
  end

  test "accepts 500 characters and rejects 501 in Active Record" do
    accepted = build_post(body: "a" * 500)
    rejected = build_post(body: "a" * 501)

    assert accepted.valid?
    assert_not rejected.valid?
    assert_includes rejected.errors.details[:body].map { |detail| detail[:error] }, :too_long
  end

  test "database constraint rejects a body longer than 500 characters" do
    post = build_post(body: "Court et fraternel")
    post.save!

    assert_raises ActiveRecord::StatementInvalid do
      post.update_columns(body: "a" * 501)
    end
  end

  test "rejects links html invisible-only text and cross-ward parents" do
    assert_not build_post(body: "https://example.org").valid?
    assert_not build_post(body: "<strong>Discours</strong>").valid?
    assert_not build_post(body: "\u200B\u200D").valid?

    other_ward = extra_ward(31, scripture_circle_mode: "active")
    other_person = Person.create!(ward: other_ward, given_name: "Autre", avatar_key: "delfin", locale: "fr")
    other_thread = other_ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    other_post = other_thread.scripture_circle_posts.create!(
      ward: other_ward, person: other_person, kind: "reflection", locale: "fr", body: "Autre cercle"
    )

    reply = build_post(body: "Réponse", kind: "reply", parent: other_post)
    assert_not reply.valid?
  end

  test "records immutable revisions on creation edit and author deletion" do
    post = build_post(body: "Première pensée")
    post.save!
    assert_equal [ "created" ], post.scripture_circle_post_revisions.pluck(:change_kind)

    post.update!(body: "Pensée précisée", edited_at: Time.current)
    post.update!(status: "author_deleted", deleted_at: Time.current)

    assert_equal %w[created edited author_deleted], post.scripture_circle_post_revisions.order(:revision_number).pluck(:change_kind)
    assert_equal 3, post.scripture_circle_post_revisions.distinct.count(:content_digest)
  end

  test "is anonymous by default, lets its author change that choice, and keeps the change in history" do
    post = build_post(body: "Une pensée portée anonymement.")
    post.save!
    other_member = people(:carmen_lopez)

    assert_predicate post, :anonymous?
    assert_equal I18n.t("scripture_reader.circle.anonymous"), post.author_name_for(other_member)
    assert_equal I18n.t("scripture_reader.circle.you"), post.author_name_for(@person)

    post.update!(anonymous: false)
    assert_equal @person.display_name, post.author_name_for(other_member)
    revision = post.scripture_circle_post_revisions.order(:revision_number).last
    assert_equal "anonymity_changed", revision.change_kind
    assert_not revision.anonymous?
  end

  private

    def build_post(body:, kind: "reflection", parent: nil)
      @thread.scripture_circle_posts.build(
        ward: @ward, person: @person, kind:, parent:, locale: "fr", body:
      )
    end
end
