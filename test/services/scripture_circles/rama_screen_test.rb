require "test_helper"

class ScriptureCircles::RamaScreenTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:pili)
    @author = people(:carmen_garcia)
    @other_member = people(:carmen_lopez)
  end

  test "builds a complete ordered conversation with safe participant and chapter metadata" do
    root = create_root(
      person: @author,
      body: "Comment puis-je mieux comprendre ce verset ?",
      selected_text: "Une semence est une bonne chose.",
      at: Time.zone.parse("2026-08-20 08:00")
    )
    first_reply = create_reply(
      parent: root,
      person: @other_member,
      body: "Je commence par relire une phrase à la fois.",
      at: Time.zone.parse("2026-08-20 09:00")
    )
    nested_reply = create_reply(
      parent: first_reply,
      person: @viewer,
      body: "Merci, cette manière de faire me donne de l'élan.",
      at: Time.zone.parse("2026-08-20 10:00")
    )
    sibling_reply = create_reply(
      parent: root,
      person: @other_member,
      body: "Je note aussi ce que ce chapitre change dans ma journée.",
      at: Time.zone.parse("2026-08-20 11:00")
    )

    screen = screen_for
    card = screen.conversations.find { |candidate| candidate.root_id == root.id }

    assert_equal [ root.id, first_reply.id, nested_reply.id, sibling_reply.id ], card.conversation.map(&:id)
    assert_equal [ nil, root.id, first_reply.id, root.id ], card.conversation.map(&:parent_id)
    assert_equal [ true, false, false, false ], card.conversation.map(&:root?)
    assert_equal "Une semence est une bonne chose.", card.root.selected_text
    assert_equal @author.display_name, card.root.author_name
    assert_equal I18n.t("scripture_reader.circle.you", locale: :fr), card.conversation.third.author_name
    assert_equal 3, card.reply_count

    assert_equal "ot/ps/52", card.chapter.reference
    assert_equal "Psaumes 52", card.chapter.title
    assert_equal Rails.application.routes.url_helpers.scripture_path("ot/ps/52"), card.chapter.reader_path

    assert_equal [ @author.display_name, @other_member.display_name, I18n.t("scripture_reader.circle.you", locale: :fr) ],
      card.participants.map(&:name)
    assert_equal [ @author.avatar_key, @other_member.avatar_key, @viewer.avatar_key ], card.participants.map(&:avatar_key)

    refute_respond_to card, :post
    refute_respond_to card.root, :person
    refute_respond_to card.participants.first, :person_id
  end

  test "selects the first active conversation by default and honors only a visible requested selection" do
    first = create_root(person: @author, body: "La première question est plus ancienne.", at: Time.zone.parse("2026-08-20 08:00"))
    second = create_root(person: @other_member, body: "La deuxième question est plus récente.", at: Time.zone.parse("2026-08-20 09:00"))

    default_screen = screen_for
    assert_equal second.id, default_screen.selected.root_id
    assert_not default_screen.selected_explicitly

    selected_screen = screen_for(conversation: first.id)
    assert_equal first.id, selected_screen.selected.root_id
    assert_predicate selected_screen, :selected_explicitly

    stale_screen = screen_for(conversation: 999_999)
    assert_equal second.id, stale_screen.selected.root_id
    assert_not stale_screen.selected_explicitly
  end

  test "keeps a valid selected thread open through a legacy help link" do
    question = create_root(person: @author, body: "Cette question est encore dans À aider.")
    create_reply(parent: question, person: @other_member, body: "Une autre personne vient de répondre.")

    screen = screen_for(view: "help", conversation: question.id)

    assert_equal [ question.id ], screen.conversations.map(&:root_id)
    assert_equal "all", screen.active_view
    assert_equal question.id, screen.selected.root_id
    assert_predicate screen, :selected_explicitly
    assert_equal 2, screen.selected.conversation.size
  end

  test "does not reveal an anonymous root author's identity through rows participants or avatar metadata" do
    anonymous_root = create_root(
      person: @author,
      body: "Puis-je demander de l'aide sans afficher mon prénom ?",
      author_visibility: "anonymous_to_ward"
    )
    create_reply(
      parent: anonymous_root,
      person: @other_member,
      body: "Merci de partager cela avec la rama."
    )

    card = screen_for.conversations.find { |candidate| candidate.root_id == anonymous_root.id }
    root_row = card.root
    anonymous_participant = card.participants.find(&:anonymous?)

    assert_predicate root_row, :anonymous?
    assert_nil root_row.avatar_key
    assert_equal I18n.t("scripture_reader.circle.anonymous", locale: :fr), root_row.author_name
    assert_predicate anonymous_participant, :anonymous?
    assert_nil anonymous_participant.avatar_key
    assert_equal I18n.t("scripture_reader.circle.anonymous", locale: :fr), anonymous_participant.name
    assert_not_includes card.conversation.map(&:author_name), @author.display_name
    assert_not_includes card.participants.map(&:name), @author.display_name
    refute_respond_to root_row, :person_id
  end

  test "redacts a named former member rather than leaking stale ward identity" do
    root = create_root(
      person: @author,
      body: "Cette réflexion reste dans le fil après un départ de la rama.",
      kind: "reflection"
    )
    former_ward = extra_ward(74, scripture_circle_mode: "active")
    @author.update!(ward: former_ward)

    card = screen_for.conversations.find { |candidate| candidate.root_id == root.id }

    assert_equal I18n.t("scripture_reader.circle.former_member", locale: :fr), card.root.author_name
    assert_nil card.root.avatar_key
    assert_equal I18n.t("scripture_reader.circle.former_member", locale: :fr), card.participants.first.name
    assert_nil card.participants.first.avatar_key
    assert_not_includes card.conversation.map(&:author_name), @author.display_name
  end

  test "merges help and recent conversations into one inbox while retaining mine" do
    unanswered = create_root(
      person: @author,
      body: "Comment puis-je appliquer cette parole cette semaine ?",
      at: Time.zone.parse("2026-08-20 08:00")
    )
    same_author_reply = create_root(
      person: @other_member,
      body: "Que puis-je relire pour avancer ?",
      at: Time.zone.parse("2026-08-20 09:00")
    )
    create_reply(
      parent: same_author_reply,
      person: @other_member,
      body: "Je vais d'abord relire le passage.",
      at: Time.zone.parse("2026-08-20 10:00")
    )
    answered = create_root(
      person: @author,
      body: "Comment garder confiance cette semaine ?",
      at: Time.zone.parse("2026-08-20 07:00")
    )
    create_reply(
      parent: answered,
      person: @viewer,
      body: "Je peux partager une expérience simple.",
      at: Time.zone.parse("2026-08-20 11:00")
    )
    own_question = create_root(
      person: @viewer,
      body: "Puis-je demander un peu d'aide ici ?",
      at: Time.zone.parse("2026-08-20 12:00")
    )

    default_inbox = screen_for
    all = screen_for(view: "all")
    legacy_help = screen_for(view: "help")
    legacy_recent = screen_for(view: "recent")
    mine = screen_for(view: "mine")

    assert_equal 2, default_inbox.help_count
    assert_equal "all", default_inbox.active_view
    expected_all = [ own_question.id, answered.id, same_author_reply.id, unanswered.id ]
    assert_equal expected_all, default_inbox.conversations.map(&:root_id)
    assert_equal expected_all, all.conversations.map(&:root_id)
    assert_equal expected_all, legacy_help.conversations.map(&:root_id)
    assert_equal expected_all, legacy_recent.conversations.map(&:root_id)
    assert_equal [ own_question.id, answered.id ], mine.conversations.map(&:root_id)
    assert_equal "all", all.active_view
    assert_equal "all", legacy_help.active_view
    assert_equal "all", legacy_recent.active_view
    assert_equal "mine", mine.active_view
  end

  test "ranks the active list by community score before activity with deterministic ties" do
    highly_supported = create_root(
      person: @author,
      body: "Cette réflexion plus ancienne reçoit un vrai soutien.",
      kind: "reflection",
      at: Time.zone.parse("2026-08-20 08:00")
    )
    older_tie = create_root(
      person: @author,
      body: "Cette réflexion sans vote est plus ancienne.",
      kind: "reflection",
      at: Time.zone.parse("2026-08-20 09:00")
    )
    newer_tie = create_root(
      person: @other_member,
      body: "Cette réflexion sans vote est plus récente.",
      kind: "reflection",
      at: Time.zone.parse("2026-08-20 10:00")
    )
    downvoted = create_root(
      person: @other_member,
      body: "Cette réflexion récente doit descendre après les autres.",
      kind: "reflection",
      at: Time.zone.parse("2026-08-20 11:00")
    )

    ScriptureCircleConversationVote.create!(conversation_root: highly_supported, ward: @ward, voter_person: @viewer, direction: "up")
    ScriptureCircleConversationVote.create!(conversation_root: highly_supported, ward: @ward, voter_person: @other_member, direction: "up")
    ScriptureCircleConversationVote.create!(conversation_root: downvoted, ward: @ward, voter_person: @viewer, direction: "down")
    ScriptureCircleConversationVote.create!(conversation_root: downvoted, ward: @ward, voter_person: @author, direction: "down")

    screen = screen_for(view: "recent")

    assert_equal [ highly_supported.id, newer_tie.id, older_tie.id, downvoted.id ], screen.conversations.map(&:root_id)
  end

  test "paginates the active inbox without replacing its filters" do
    13.times do |index|
      create_root(
        person: index.even? ? @author : @other_member,
        body: "Réflexion visible numéro #{index + 1}.",
        kind: "reflection",
        at: Time.zone.parse("2026-08-20 #{8 + index}:00")
      )
    end

    first_page = screen_for
    second_page = screen_for(page: 2)

    assert_equal 12, first_page.conversations.size
    assert_equal 2, first_page.next_page
    assert_equal 1, second_page.conversations.size
    assert_nil second_page.next_page
  end

  test "excludes archived invalid non-visible and other ward conversations" do
    visible_root = create_root(person: @author, body: "Cette réflexion visible doit apparaître.", kind: "reflection")
    archived_root = create_root(
      person: @other_member,
      body: "Ce fil archivé ne doit pas apparaître.",
      kind: "reflection",
      reference: "bofm/alma/32"
    )
    archived_root.scripture_circle_thread.update!(status: "archived")
    censored_root = create_root(
      person: @other_member,
      body: "Cette réflexion censurée ne doit pas apparaître.",
      kind: "reflection",
      reference: "bofm/mosiah/2"
    )
    censored_root.update_columns(status: "community_censored")

    invalid_thread = @ward.scripture_circle_threads.create!(reference: "bofm/2-ne/25")
    invalid_thread.update_column(:reference, "not-a-scripture/99")
    invalid_root = invalid_thread.scripture_circle_posts.create!(
      ward: @ward,
      person: @other_member,
      kind: "reflection",
      locale: "fr",
      body: "Ce fil invalide ne doit pas apparaître."
    )

    other_ward = extra_ward(73, scripture_circle_mode: "active")
    outsider = Person.create!(ward: other_ward, given_name: "Autre", avatar_key: "delfin", locale: "fr")
    other_thread = other_ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    other_root = other_thread.scripture_circle_posts.create!(
      ward: other_ward,
      person: outsider,
      kind: "reflection",
      locale: "fr",
      body: "Cette autre rama ne doit pas apparaître."
    )

    screen = screen_for

    assert_equal [ visible_root.id ], screen.conversations.map(&:root_id)
    assert_not_includes screen.conversations.map(&:root_id), archived_root.id
    assert_not_includes screen.conversations.map(&:root_id), censored_root.id
    assert_not_includes screen.conversations.map(&:root_id), invalid_root.id
    assert_not_includes screen.conversations.map(&:root_id), other_root.id
  end

  test "does not count or render a visible descendant below a censored or deleted ancestor" do
    censored_root = create_root(
      person: @author,
      body: "Cette question reste ouverte malgré une réponse censurée.",
      at: Time.zone.parse("2026-08-20 08:00")
    )
    censored_parent = create_reply(
      parent: censored_root,
      person: @author,
      body: "Cette réponse intermédiaire sera censurée.",
      at: Time.zone.parse("2026-08-20 09:00")
    )
    censored_descendant = create_reply(
      parent: censored_parent,
      person: @viewer,
      body: "Cette réponse visible ne doit pas traverser la censure.",
      at: Time.zone.parse("2026-08-20 10:00")
    )
    censored_parent.update_columns(status: "community_censored")

    deleted_root = create_root(
      person: @author,
      body: "Cette autre question reste ouverte après une suppression.",
      at: Time.zone.parse("2026-08-20 11:00")
    )
    deleted_parent = create_reply(
      parent: deleted_root,
      person: @author,
      body: "Cette réponse intermédiaire sera supprimée.",
      at: Time.zone.parse("2026-08-20 12:00")
    )
    deleted_descendant = create_reply(
      parent: deleted_parent,
      person: @viewer,
      body: "Cette réponse visible ne doit pas traverser la suppression.",
      at: Time.zone.parse("2026-08-20 13:00")
    )
    deleted_parent.update_columns(status: "author_deleted", deleted_at: Time.current)

    screen = screen_for
    cards = screen.conversations.index_by(&:root_id)

    assert_equal [ censored_root.id ], cards.fetch(censored_root.id).conversation.map(&:id)
    assert_equal [ deleted_root.id ], cards.fetch(deleted_root.id).conversation.map(&:id)
    assert_equal 0, cards.fetch(censored_root.id).reply_count
    assert_equal 0, cards.fetch(deleted_root.id).reply_count
    assert_not_includes cards.fetch(censored_root.id).conversation.map(&:id), censored_descendant.id
    assert_not_includes cards.fetch(deleted_root.id).conversation.map(&:id), deleted_descendant.id
  end

  test "keeps a legitimately deep visible reply chain fully renderable" do
    root = create_root(person: @author, body: "Cette question reçoit une conversation très approfondie.")
    parent = root
    ids = [ root.id ]
    65.times do |index|
      parent = create_reply(
        parent:,
        person: @viewer,
        body: "Réponse imbriquée numéro #{index + 1}."
      )
      ids << parent.id
    end

    screen = screen_for(view: "recent")
    card = screen.conversations.find { |candidate| candidate.root_id == root.id }

    assert_equal ids, card.conversation.map(&:id)
    assert_equal 65, card.reply_count
  end

  test "loads a page of full conversations without per-message queries" do
    5.times do |index|
      root = create_root(
        person: index.even? ? @author : @other_member,
        body: "Réflexion visible numéro #{index + 1}.",
        kind: "reflection",
        at: Time.zone.parse("2026-08-20 #{8 + index}:00")
      )
      create_reply(parent: root, person: @viewer, body: "Réponse #{index + 1}.")
    end

    screen = nil
    query_count = count_sql_queries do
      screen = screen_for(view: "recent")
    end

    assert_equal 5, screen.conversations.size
    assert screen.conversations.all? { |card| card.conversation.size == 2 }
    assert_operator query_count, :<=, 8
  end

  test "honors readable state and rejects disabled Circle access" do
    @ward.update!(scripture_circle_mode: "read_only")
    assert_equal "read_only", screen_for.state

    @ward.update!(scripture_circle_mode: "disabled")
    assert_raises ScriptureCircles::Access::Disabled do
      screen_for
    end
  end

  private

    def screen_for(view: nil, page: nil, conversation: nil)
      ScriptureCircles::RamaScreen.call(
        person: @viewer,
        locale: "fr",
        view:,
        page:,
        conversation:
      )
    end

    def create_root(person:, body:, kind: "question", reference: "ot/ps/52", author_visibility: "named", selected_text: nil, at: Time.current)
      thread = @ward.scripture_circle_threads.find_or_create_by!(reference:)
      travel_to(at) do
        thread.scripture_circle_posts.create!(
          ward: @ward,
          person:,
          kind:,
          locale: "fr",
          body:,
          author_visibility:,
          selected_text:
        )
      end
    end

    def create_reply(parent:, person:, body:, at: Time.current)
      travel_to(at) do
        parent.scripture_circle_thread.scripture_circle_posts.create!(
          ward: @ward,
          person:,
          kind: "reply",
          parent:,
          locale: "fr",
          body:
        )
      end
    end

    def count_sql_queries
      count = 0
      callback = lambda do |_event, _started, _finished, _id, payload|
        next if payload[:name].in?(%w[SCHEMA TRANSACTION])

        count += 1
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
      count
    end
end
