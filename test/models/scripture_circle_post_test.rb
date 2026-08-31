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

  test "roots point to themselves and every nested reply keeps the top conversation root" do
    root = build_post(kind: "question", body: "Comment puis-je mieux comprendre ce passage ?")
    root.save!
    reply = @thread.scripture_circle_posts.create!(
      ward: @ward,
      person: people(:carmen_lopez),
      kind: "reply",
      parent: root,
      locale: "fr",
      body: "Regardons le verset juste avant."
    )
    nested_reply = @thread.scripture_circle_posts.create!(
      ward: @ward,
      person: people(:pili),
      kind: "reply",
      parent: reply,
      locale: "fr",
      body: "Cette piste m'aide aussi."
    )

    assert_equal root.id, root.conversation_root_id
    assert_equal root.id, reply.conversation_root_id
    assert_equal root.id, nested_reply.conversation_root_id
    assert_equal root, nested_reply.root_post
  end

  test "defaults to named visibility and permits anonymity only for question roots" do
    post = build_post(body: "Une pensée portée avec mon prénom.")
    post.save!
    other_member = people(:carmen_lopez)

    assert_predicate post, :named?
    assert_not post.anonymous?
    assert_equal @person.display_name, post.author_name_for(other_member)

    anonymous_question = build_post(
      kind: "question",
      body: "Puis-je demander de l'aide sans afficher mon prénom ?",
      author_visibility: "anonymous_to_ward"
    )
    assert anonymous_question.valid?
    anonymous_question.save!
    assert_predicate anonymous_question, :anonymous?
    assert_equal I18n.t("scripture_reader.circle.anonymous"), anonymous_question.author_name_for(other_member)
    assert_equal I18n.t("scripture_reader.circle.you"), anonymous_question.author_name_for(@person)

    anonymous_reflection = build_post(
      body: "Cette réflexion ne doit pas pouvoir devenir anonyme.",
      author_visibility: "anonymous_to_ward"
    )
    assert_not anonymous_reflection.valid?
    assert_includes anonymous_reflection.errors.details[:author_visibility].map { |detail| detail[:error] }, :invalid

    anonymous_reply = build_post(
      kind: "reply",
      parent: anonymous_question,
      body: "Une réponse reste toujours signée.",
      author_visibility: "anonymous_to_ward"
    )
    assert_not anonymous_reply.valid?
  end

  test "records semantic anonymity changes in immutable revisions" do
    post = build_post(kind: "question", body: "Une question que je préfère signer.")
    post.save!

    post.update!(author_visibility: "anonymous_to_ward")
    anonymous_revision = post.scripture_circle_post_revisions.order(:revision_number).last
    assert_equal "anonymity_changed", anonymous_revision.change_kind
    assert_equal "anonymous_to_ward", anonymous_revision.author_visibility
    assert_predicate anonymous_revision, :anonymous?

    post.update!(author_visibility: "named")
    named_revision = post.scripture_circle_post_revisions.order(:revision_number).last
    assert_equal "anonymity_changed", named_revision.change_kind
    assert_equal "named", named_revision.author_visibility
    assert_not named_revision.anonymous?
  end

  test "normalizes a manually chosen list of verses and keeps it aligned with its passage" do
    post = build_post(
      body: "Je veux relire ces passages lentement.",
      start_verse: 2,
      end_verse: 6,
      selected_verses: "2, 4-6",
      selected_text: "Texte des versets choisis."
    )

    assert_predicate post, :valid?
    post.save!
    assert_equal "2, 4-6", post.selected_verses

    misaligned = build_post(
      body: "Cette sélection ne correspond pas à son ancre.",
      start_verse: 3,
      end_verse: 6,
      selected_verses: "2, 4-6",
      selected_text: "Texte des versets choisis."
    )
    assert_not misaligned.valid?
    assert_includes misaligned.errors.details[:selected_verses].map { |detail| detail[:error] }, :invalid

    malformed = build_post(
      body: "Cette sélection ne peut pas contenir une plage déraisonnable.",
      start_verse: 1,
      end_verse: 999_999,
      selected_verses: "1-999999",
      selected_text: "Texte des versets choisis."
    )
    assert_not malformed.valid?
  end

  test "does not expose internal showcase markers as a passage" do
    showcase_post = build_post(
      body: "Cette question doit rester lisible sans son identifiant de démonstration.",
      selected_text: "scripture-circle-showcase-v1:alma-question"
    )
    passage_post = build_post(
      body: "Ce passage garde son contexte quand il a été choisi par une personne.",
      selected_text: "Une parole réellement sélectionnée."
    )

    assert_nil showcase_post.selected_text_for_display
    assert_equal "Une parole réellement sélectionnée.", passage_post.selected_text_for_display
  end

  private

    def build_post(body:, kind: "reflection", parent: nil, author_visibility: nil, **attributes)
      @thread.scripture_circle_posts.build(
        ward: @ward, person: @person, kind:, parent:, locale: "fr", body:, author_visibility:, **attributes
      )
    end
end
