require "test_helper"

class ScriptureCircles::PublishTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @first_person = people(:carmen_garcia)
    @second_person = people(:carmen_lopez)
  end

  test "reuses the ward chapter thread and defaults new posts to named visibility" do
    first = ScriptureCircles::Publish.call(
      person: @first_person, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Première parole courte." }
    )
    second = ScriptureCircles::Publish.call(
      person: @second_person, reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Quelle lumière gardons-nous ensemble ?" }
    )

    assert_equal first.scripture_circle_thread_id, second.scripture_circle_thread_id
    assert_equal 1, @ward.scripture_circle_threads.where(reference: "ot/ps/52").count
    assert_predicate first, :named?
    assert_predicate second, :named?
    assert_equal first.id, first.conversation_root_id
    assert_equal second.id, second.conversation_root_id

    anonymous_question = ScriptureCircles::Publish.call(
      person: @first_person, reference: "ot/ps/52",
      attributes: {
        kind: "question", locale: "fr", body: "Puis-je poser cette question sans montrer mon prénom ?",
        author_visibility: "anonymous_to_ward"
      }
    )
    assert_predicate anonymous_question, :anonymous?
    assert_equal "anonymous_to_ward", anonymous_question.author_visibility
  end

  test "keeps legacy anonymous input harmless and assigns every reply to the top root" do
    legacy_reflection = ScriptureCircles::Publish.call(
      person: @first_person,
      reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette réflexion reste signée.", anonymous: true }
    )
    legacy_question = ScriptureCircles::Publish.call(
      person: @first_person,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Puis-je demander cela anonymement ?", anonymous: true }
    )
    reply = ScriptureCircles::Publish.call(
      person: @second_person,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", body: "Je peux partager une piste.", parent_id: legacy_question.id, anonymous: true }
    )
    nested_reply = ScriptureCircles::Publish.call(
      person: @first_person,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", body: "Merci pour cette piste.", parent_id: reply.id }
    )

    assert_predicate legacy_reflection, :named?
    assert_predicate legacy_question, :anonymous?
    assert_predicate reply, :named?
    assert_equal legacy_question.id, reply.conversation_root_id
    assert_equal legacy_question.id, nested_reply.conversation_root_id
  end

  test "does not publish into an archived chapter thread" do
    thread = @ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    thread.update!(status: "archived")

    assert_raises ScriptureCircles::Access::ArchivedThread do
      ScriptureCircles::Publish.call(
        person: @first_person,
        reference: "ot/ps/52",
        attributes: { kind: "question", locale: "fr", body: "Cette question ne doit pas être publiée." }
      )
    end
    assert_empty thread.scripture_circle_posts
  end

  test "persists an exact manual list of verses with its selected text" do
    post = ScriptureCircles::Publish.call(
      person: @first_person,
      reference: "ot/ps/52",
      attributes: {
        kind: "reflection", locale: "fr", body: "Je veux garder ces mots ensemble.",
        start_verse: 2, end_verse: 6, selected_verses: "2, 4-6",
        selected_text: "Le texte des versets 2, 4, 5 et 6."
      }
    )

    assert_equal "2, 4-6", post.selected_verses
    assert_equal [ 2, 6 ], [ post.start_verse, post.end_verse ]
  end

  test "does not append below a visible descendant when its conversation root is no longer visible" do
    root = ScriptureCircles::Publish.call(
      person: @first_person,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Puis-je recevoir de l'aide sur ce passage ?" }
    )
    visible_reply = ScriptureCircles::Publish.call(
      person: @second_person,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", body: "Je peux proposer une lecture.", parent_id: root.id }
    )
    root.update!(status: "author_deleted", deleted_at: Time.current)

    assert_equal "visible", visible_reply.reload.status
    assert_raises ActiveRecord::RecordInvalid do
      ScriptureCircles::Publish.call(
        person: @first_person,
        reference: "ot/ps/52",
        attributes: { kind: "reply", locale: "fr", body: "Cette suite doit être refusée.", parent_id: visible_reply.id }
      )
    end
  end
end
