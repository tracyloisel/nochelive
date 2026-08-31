require "test_helper"

class Scriptures::ReaderScreenTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:carmen_garcia)
    @author = people(:carmen_lopez)
    @thread = @ward.scripture_circle_threads.find_or_create_by!(reference: "ot/ps/52")
  end

  test "loads a visible target conversation even when its posts are outside the newest preview" do
    target = create_post(kind: "question", body: "Une question ancienne doit rester atteignable.")
    reply = create_post(kind: "reply", parent: target, body: "Sa réponse doit accompagner le lien direct.")
    21.times { |index| create_post(kind: "reflection", body: "Partage récent de la paroisse #{index}.") }

    preview = Scriptures::ReaderScreen.call(person: @viewer, reference: "ot/ps/52", locale: "fr")
    refute_includes preview.circle_posts, target
    refute_includes preview.circle_posts, reply

    focused = Scriptures::ReaderScreen.call(
      person: @viewer, reference: "ot/ps/52", locale: "fr", circle_post_id: target.id
    )

    assert_equal target.id, focused.circle_focus_post.id
    assert_not focused.circle_focus_unavailable
    assert_includes focused.circle_posts, target
    assert_includes focused.circle_posts, reply
  end

  test "keeps a visible focus open when a reply moves its root out of unresolved" do
    target = create_post(kind: "question", body: "Cette question était ouverte au moment du clic.")
    reply = create_post(kind: "reply", parent: target, body: "Elle vient de recevoir une réponse visible.")
    21.times { |index| create_post(kind: "question", body: "Question non résolue numéro #{index + 1}.") }

    result = Scriptures::ReaderScreen.call(
      person: @viewer,
      reference: "ot/ps/52",
      locale: "fr",
      circle_sort: "unresolved",
      circle_post_id: target.id
    )

    assert_equal "unresolved", result.circle_sort
    assert_equal target.id, result.circle_focus_post.id
    assert_includes result.circle_posts, target
    assert_includes result.circle_posts, reply
  end

  test "groups each popular root with its replies and ranks scores before activity" do
    high_score_root = nil
    newer_zero_score_root = nil
    downvoted_root = nil
    high_score_reply = nil

    travel_to(Time.zone.parse("2026-08-20 08:00")) do
      high_score_root = create_post(kind: "question", body: "Cette conversation plus ancienne est très soutenue.")
    end
    travel_to(Time.zone.parse("2026-08-20 10:00")) do
      newer_zero_score_root = create_post(kind: "reflection", body: "Cette conversation est plus récente mais neutre.")
    end
    travel_to(Time.zone.parse("2026-08-20 11:00")) do
      high_score_reply = create_post(kind: "reply", parent: high_score_root, body: "Cette réponse reste avec sa racine.")
    end
    travel_to(Time.zone.parse("2026-08-20 12:00")) do
      downvoted_root = create_post(kind: "reflection", body: "Cette conversation récente est moins bien reçue.")
    end

    ScriptureCircleConversationVote.create!(
      conversation_root: high_score_root, ward: @ward, voter_person: @viewer, direction: "up"
    )
    ScriptureCircleConversationVote.create!(
      conversation_root: downvoted_root, ward: @ward, voter_person: @viewer, direction: "down"
    )

    result = Scriptures::ReaderScreen.call(
      person: @viewer,
      reference: "ot/ps/52",
      locale: "fr",
      circle_sort: "popular"
    )

    assert_equal [ high_score_root.id, high_score_reply.id, newer_zero_score_root.id, downvoted_root.id ],
      result.circle_posts.map(&:id)
    assert_equal "popular", result.circle_sort
    assert_equal 1, result.circle_posts.first.conversation_vote_score
    assert_equal(-1, result.circle_posts.last.conversation_vote_score)
  end

  test "defaults to recent and ignores the vote score when ordering visible roots" do
    popular_but_older = nil
    newest = nil

    travel_to(Time.zone.parse("2026-08-20 08:00")) do
      popular_but_older = create_post(kind: "question", body: "Cette question reçoit beaucoup de soutien.")
    end
    travel_to(Time.zone.parse("2026-08-20 09:00")) do
      newest = create_post(kind: "reflection", body: "Cette réflexion est simplement plus récente.")
    end

    ScriptureCircleConversationVote.create!(
      conversation_root: popular_but_older, ward: @ward, voter_person: @viewer, direction: "up"
    )

    result = Scriptures::ReaderScreen.call(person: @viewer, reference: "ot/ps/52", locale: "fr")

    assert_equal "recent", result.circle_sort
    assert_equal [ newest.id, popular_but_older.id ], result.circle_posts.select(&:root?).map(&:id)
    assert_equal({ recent: 2, popular: 2, unresolved: 1 }, result.circle_counts)
  end

  test "marks questions unresolved only while no visible reply remains, including an author reply" do
    hidden_chain_root = nil
    hidden_parent = nil
    hidden_descendant = nil
    author_answered = nil
    member_answered = nil

    travel_to(Time.zone.parse("2026-08-20 08:00")) do
      hidden_chain_root = create_post(kind: "question", body: "Cette question reste sans réponse visible.")
    end
    travel_to(Time.zone.parse("2026-08-20 08:30")) do
      hidden_parent = create_post(kind: "reply", parent: hidden_chain_root, body: "Cette réponse sera retirée.")
    end
    travel_to(Time.zone.parse("2026-08-20 09:00")) do
      hidden_descendant = create_post(kind: "reply", parent: hidden_parent, body: "Cette réponse visible ne doit pas traverser le retrait.")
    end
    hidden_parent.update_columns(status: "author_deleted", deleted_at: Time.current)

    travel_to(Time.zone.parse("2026-08-20 10:00")) do
      author_answered = create_post(kind: "question", body: "Cette question reçoit la réponse de son auteur.")
    end
    travel_to(Time.zone.parse("2026-08-20 11:00")) do
      create_post(kind: "reply", parent: author_answered, body: "Je précise ma propre question.")
    end

    travel_to(Time.zone.parse("2026-08-20 12:00")) do
      member_answered = create_post(kind: "question", body: "Cette question reçoit une réponse d’un membre.")
    end
    travel_to(Time.zone.parse("2026-08-20 13:00")) do
      create_post(kind: "reply", parent: member_answered, body: "Voici une aide simple pour continuer.")
    end

    result = Scriptures::ReaderScreen.call(
      person: @viewer,
      reference: "ot/ps/52",
      locale: "fr",
      circle_sort: "unresolved"
    )

    assert_equal "unresolved", result.circle_sort
    assert_equal [ hidden_chain_root.id ], result.circle_posts.select(&:root?).map(&:id)
    assert_equal 1, result.circle_counts.fetch(:unresolved)
    refute_includes result.circle_posts.map(&:id), hidden_descendant.id
  end

  test "does not rank a root by activity hidden behind a non-visible parent" do
    older_root = nil
    hidden_parent = nil
    hidden_descendant = nil
    newer_visible_root = nil

    travel_to(Time.zone.parse("2026-08-20 08:00")) do
      older_root = create_post(kind: "question", body: "Cette conversation a commencé plus tôt.")
    end
    travel_to(Time.zone.parse("2026-08-20 08:10")) do
      hidden_parent = create_post(kind: "reply", parent: older_root, body: "Cette réponse sera ensuite retirée.")
    end
    travel_to(Time.zone.parse("2026-08-20 09:00")) do
      newer_visible_root = create_post(kind: "reflection", body: "Cette conversation visible est plus récente.")
    end
    travel_to(Time.zone.parse("2026-08-20 10:00")) do
      hidden_descendant = create_post(kind: "reply", parent: hidden_parent, body: "Cette activité ne doit pas remonter la conversation.")
    end
    hidden_parent.update!(status: "author_deleted", deleted_at: Time.current)

    result = Scriptures::ReaderScreen.call(person: @viewer, reference: "ot/ps/52", locale: "fr")

    assert_equal [ newer_visible_root.id, older_root.id, hidden_parent.id ], result.circle_posts.map(&:id)
    refute_includes result.circle_posts.map(&:id), hidden_descendant.id
  end

  test "returns a nonrevealing unavailable focus state for an inactive conversation" do
    target = create_post(kind: "question", body: "Cette conversation ne doit plus être atteignable.")
    @thread.update!(status: "archived")

    result = Scriptures::ReaderScreen.call(
      person: @viewer, reference: "ot/ps/52", locale: "fr", circle_post_id: target.id
    )

    assert_nil result.circle_thread
    assert_nil result.circle_focus_post
    assert_predicate result, :circle_focus_unavailable
    assert_empty result.circle_posts
  end

  test "resolves a deeply nested target with bounded Circle queries" do
    target = create_post(kind: "question", body: "Une question au début de la conversation.")
    10.times do |index|
      target = create_post(
        kind: "reply",
        parent: target,
        body: "Réponse imbriquée numéro #{index + 1}."
      )
    end

    result = nil
    query_count = count_sql_queries(matching: /scripture_circle_posts/) do
      result = Scriptures::ReaderScreen.call(
        person: Person.find(@viewer.id),
        reference: "ot/ps/52",
        locale: "fr",
        circle_post_id: target.id
      )
    end

    assert_equal target.id, result.circle_focus_post.id
    # The root map is fetched once and reused while merging the conversation.
    # A parent-by-parent traversal would grow this total with the nesting depth.
    assert_operator query_count, :<=, 12
  end

  private

    def create_post(kind:, body:, parent: nil)
      @thread.scripture_circle_posts.create!(
        ward: @ward,
        person: @author,
        parent:,
        kind:,
        locale: "fr",
        body:,
        author_visibility: "named"
      )
    end

    def count_sql_queries(matching: nil)
      count = 0
      callback = lambda do |_event, _started, _finished, _id, payload|
        next if payload[:name].in?(%w[SCHEMA TRANSACTION])
        next if matching && !payload[:sql].to_s.match?(matching)

        count += 1
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
      count
    end
end
