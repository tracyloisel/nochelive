require "test_helper"

class ScriptureReaderThreeControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @author = people(:carmen_garcia)
    @other_member = people(:carmen_lopez)
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "persists only valid closed-set reading preferences" do
    sign_in_person(@author)

    patch scripture_reader_preferences_path, params: {
      preference: { font_scale: 130, line_height_key: "ample", measure_key: "focused", background_key: "soft" }
    }, as: :json

    assert_response :success
    assert_equal 130, response.parsed_body.fetch("font_scale")
    assert_equal "ample", @author.reload.scripture_reader_preference.line_height_key

    patch scripture_reader_preferences_path, params: {
      preference: { font_scale: 777, background_key: "blue" }
    }, as: :json
    assert_response :unprocessable_entity
    assert_equal 130, @author.scripture_reader_preference.reload.font_scale
  end

  test "creates private marks for the signed-in person and rejects another person's deletion" do
    sign_in_person(@author)
    post scripture_marks_path, params: { mark: mark_payload }, as: :json

    assert_response :created
    mark = @author.scripture_marks.find(response.parsed_body.fetch("id"))
    assert_equal "Ce passage reste avec moi", mark.note_body
    assert_equal scripture_mark_path(mark), response.parsed_body.fetch("delete_url")

    sign_in_person(@other_member, token: "other-device")
    delete scripture_mark_path(mark), as: :json
    assert_response :not_found
    assert_nil mark.reload.discarded_at
  end

  test "creates and updates an organized private mark without requiring a visible highlight" do
    sign_in_person(@author)

    post scripture_marks_path, params: { mark: mark_payload.merge(
      visual_style: "none", color_key: nil, note_body: nil,
      tag_names: "Prière, famille", notebook_title: "Étude personnelle",
      target_reference: "ot/ps/23"
    ) }, as: :json

    assert_response :created
    mark = @author.scripture_marks.find(response.parsed_body.fetch("id"))
    assert_equal %w[famille Prière].sort, mark.scripture_tags.map(&:name).sort
    assert_equal [ "Étude personnelle" ], mark.scripture_notebooks.pluck(:title)
    assert_equal [ "ot/ps/23" ], mark.scripture_mark_links.pluck(:target_reference)

    patch scripture_mark_path(mark), params: { mark: {
      visual_style: "underline", color_key: "clay", intent_key: "gratitude",
      tag_names: "confiance", notebook_title: "Psaumes", target_reference: "ot/ps/51"
    } }, as: :json

    assert_response :success
    assert_equal "underline", mark.reload.visual_style
    assert_equal [ "confiance" ], mark.scripture_tags.pluck(:name)
    assert_equal [ "Psaumes" ], mark.scripture_notebooks.pluck(:title)
    assert_equal [ "ot/ps/51" ], mark.scripture_mark_links.pluck(:target_reference)

    post scripture_marks_path, params: { mark: mark_payload.merge(color_key: "sky") }, as: :json
    assert_response :unprocessable_entity
  end

  test "renders the localized singular psalm title and personal chapter history" do
    sign_in_person(@author)
    @author.scripture_reading_progresses.create!(
      reference: "ot/ps/52", locale: "fr", last_verse: 4, progress_ratio: 0.4,
      first_opened_at: 3.days.ago, last_opened_at: 1.hour.ago
    )

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select "#scripture-title", text: "Psaume 52"
    assert_select ".reader-mobile-title", text: "Psaume 52"
    assert_select ".reader-chapter-history", text: /Mon histoire avec ce chapitre/
    assert_select ".reader-chapter-history", text: /Psaume 52:4/
    assert_select ".reader-chapter-complete", count: 0
    assert_select "body", text: /Tu ne lis pas seul\./, count: 0
  end

  test "offers the two explicit text-size choices in reading comfort" do
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select "fieldset.reader-font-scale-options" do
      assert_select "input[type='radio'][data-preference-key='font_scale'][value='100']", count: 1
      assert_select "input[type='radio'][data-preference-key='font_scale'][value='115']", count: 1
      assert_select "span", text: "100%", count: 1
      assert_select "span", text: "115%", count: 1
      assert_select "button", count: 0
      assert_select "output", count: 0
    end
  end

  test "places a privacy-safe ward reader count above the chapter title" do
    5.times do |index|
      person = Person.create!(ward: @ward, given_name: "Lecteur #{index}", avatar_key: "delfin", locale: "fr")
      ScriptureChapterRead.create!(
        person:, ward: @ward, reference: "ot/ps/52", locale: "fr",
        reader_digest: "reader-count-#{index}", read_on: Date.current
      )
    end
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".reader-chapter-heading" do
      assert_select ".reader-chapter-readers.is-exact", text: /5 lecteurs de ta paroisse cette semaine/
      assert_select ".reader-chapter-readers + #scripture-title", text: "Psaume 52"
    end
    assert_select ".reader-mobile-readers[aria-label='5 lecteurs de ta paroisse cette semaine']", text: /5 lecteurs/
  end

  test "keeps the mobile reading progress directly beneath the reader header" do
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".scripture-sheet > .reader-room-topbar + .reader-mobile-progress", count: 1
    assert_select ".reader-mobile-progress [data-reading-progress-label]", text: /1 sur 3/
    assert_select ".reader-chapter-heading .reader-mobile-progress", count: 0
  end

  test "does not expose a small ward reader count" do
    ScriptureChapterRead.create!(
      person: @other_member, ward: @ward, reference: "ot/ps/52", locale: "fr",
      reader_digest: "single-reader-count", read_on: Date.current
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".reader-chapter-readers", text: /Des membres de ta paroisse lisent aussi ce chapitre/
    assert_select ".reader-chapter-readers", text: /1 lecteur/, count: 0
    assert_select ".reader-mobile-readers", count: 0
  end

  test "places the Circle below the chapter by default and keeps only marks in the companion" do
    ScriptureCircles::Publish.call(
      person: @other_member, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette réflexion doit rester discrète avant que je choisisse de l’ouvrir." }
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".reader-left-rail", count: 0
    assert_select ".reader-mobile-tabs", count: 0
    assert_select ".reader-companion[hidden]", count: 1
    assert_select ".reader-panel-trigger[data-action='scripture-room#toggleMarks'][data-scripture-room-target='marksTrigger'][aria-controls='reader-companion'][aria-expanded='false'][aria-label='Ouvrir mes repères'] svg.picto-bookmark", count: 1
    assert_select "a.reader-circle-trigger[href='#reader-circle'][data-action='click->scripture-room#toggleCircle'][data-scripture-room-target='circleTrigger'][aria-controls='reader-circle'][aria-expanded='false'][aria-label='Aller au cercle'] svg.picto-conversation", count: 1
    assert_select ".reader-marks-panel .reader-return-to-reading", count: 0
    assert_select "dialog#reader-companion-picker", count: 0
    assert_select "main.reader-reading-stage > section#reader-circle.reader-circle-panel", text: /Cette réflexion doit rester discrète/
    assert_select ".reader-circle-panel .reader-return-to-reading", count: 0
    assert_select ".reader-circle-compose-card[data-circle-composer-shell]", count: 1
    assert_select ".reader-circle-tabs .reader-circle-tab.is-active", text: "Récentes"
    assert_select ".reader-circle-tabs .reader-circle-tab", count: 3
    assert_select ".reader-circle-rail", count: 0
  end

  test "keeps the latest replies and every reply composer open in the conversation feed" do
    unanswered_post = ScriptureCircles::Publish.call(
      person: @other_member, reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Cette question doit rester prête à recevoir une réponse." }
    )
    existing_post = ScriptureCircles::Publish.call(
      person: @other_member, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette parole me donne de la patience." }
    )
    reply = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", parent_id: existing_post.id, body: "Je vais la relire à mon tour." }
    )
    recent_replies = 5.times.map do |index|
      ScriptureCircles::Publish.call(
        person: @other_member, reference: "ot/ps/52",
        attributes: { kind: "reply", locale: "fr", parent_id: existing_post.id, body: "Réponse récente #{index + 1}." }
      )
    end
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select "div.reader-circle-compose-card[data-circle-composer-shell]" do
      assert_select "textarea#circle-post-body", count: 1
      assert_select "button.circle-composer-secondary", count: 0
    end
    assert_select "form.reader-circle-compose-form[data-circle-composer='true'][data-circle-composer-kind='post']"
    assert_select "form.reader-circle-compose-form input[type='hidden'][name='post[kind]'][value='question']", count: 1
    assert_select "form.reader-circle-compose-form input[type='radio'][name='post[kind]']", count: 0
    assert_select "form.reader-circle-compose-form input[name='post[anonymous]']", count: 0
    assert_select "form.reader-circle-compose-form [data-circle-author-visibility]" do
      assert_select "details.reader-circle-audience[data-circle-author-visibility]" do
        assert_select "input[type='hidden'][name='post[author_visibility]'][value='named'][data-circle-author-visibility-input]", count: 1
        assert_select "summary[aria-haspopup='listbox'][aria-expanded='false']", text: "Publier avec mon nom", count: 1
        assert_select "[role='listbox'][aria-label='Identité de publication']" do
          assert_select "button[role='option'][data-author-visibility-value='named'][aria-selected='true'] span:last-child", text: "Publier avec mon nom", count: 1
          assert_select "button[role='option'][data-author-visibility-value='anonymous_to_ward'][aria-selected='false'] span:last-child", text: "Publier anonymement", count: 1
        end
      end
    end
    assert_select "#circle-post-body[placeholder='Partager une réflexion ou poser une question à ta rama…']", count: 1
    assert_select "#circle-post-body[aria-describedby~='circle-post-counter']"
    assert_select "button.reader-circle-submit[data-circle-submit]", text: /Publier/
    conversation_selector = "section.reader-circle-conversation[data-circle-conversation-root-id='#{existing_post.id}']"
    assert_select "#{conversation_selector} .reader-circle-thread-stats", text: /6 réponses.*2 participants/
    assert_select "#{conversation_selector} .reader-circle-latest-replies > .reader-circle-message.is-reply", count: 5
    assert_select "#{conversation_selector} .reader-circle-history-messages[hidden] #circle-post-#{reply.id}", count: 1
    assert_select "#{conversation_selector} button.reader-circle-history-toggle[aria-expanded='false'] .reader-circle-history-closed", text: "Voir 1 réponse précédente"
    recent_replies.each { |recent_reply| assert_select "#{conversation_selector} #circle-post-#{recent_reply.id}", count: 1 }
    assert_select "#{conversation_selector} .reader-circle-reply-composer[data-circle-composer-shell]", count: 1
    assert_select "#{conversation_selector} #reader-feed-reply-post-#{existing_post.id}-body", count: 1
    assert_select "#{conversation_selector} .reader-circle-thread-link", count: 0
    assert_select "section.reader-circle-conversation[data-circle-conversation-root-id='#{unanswered_post.id}'] .reader-circle-reply-composer[data-circle-composer-shell]", count: 1
    assert_select "#circle-post-#{existing_post.id} input[name='post[author_visibility]']", count: 0

    get scripture_path("ot/ps/52", locale: "fr", circle_post: existing_post.id)

    assert_response :success
    assert_select "section.reader-circle-thread-detail" do
      assert_select "#reader-detail-circle-post-#{existing_post.id}", text: /Cette parole me donne de la patience/
      assert_select "#reader-detail-circle-post-#{reply.id}", text: /Je vais la relire à mon tour/
      assert_select ".reader-circle-thread-detail-replies .reader-circle-message.is-reply", count: 6
      assert_select "section.reader-circle-reply-composer[data-circle-composer-shell]", count: 1
      assert_select "#reader-detail-reply-post-#{existing_post.id}-body[aria-describedby~='reader-detail-reply-post-#{existing_post.id}-counter']"
    end

    post scripture_circle_posts_path, params: { post: {
      reference: "ot/ps/52", kind: "question", locale: "fr", body: "Je veux garder cette parole près de moi aujourd’hui."
    } }

    assert_response :redirect
    assert_nil flash[:alert], flash[:alert]
    assert_match(/circle_event=published/, response.location)
    created_post = @author.scripture_circle_posts.order(:id).last
    assert_predicate created_post, :named?
    assert_predicate created_post, :question_root?
    assert_redirected_to scripture_path("ot/ps/52", locale: "fr", circle: 1, circle_event_post: created_post.id, circle_event: "published")

    follow_redirect!

    assert_select "[data-circle-event='published'][data-circle-event-post-id='#{created_post.id}']"
    assert_select "#circle-post-#{created_post.id}.is-own[data-circle-message-state='new'][tabindex='-1']"
    assert_select "#circle-post-#{created_post.id} .circle-message-author strong", text: "Toi"
    assert_select "#circle-post-#{created_post.id} .circle-message-author small", text: /Publiée anonymement/, count: 0
    assert_select "[data-circle-send-status]", text: /rejoint|joined|unido|entrou/i
  end

  test "shows a community ranking score and labeled up and down votes on another member's conversation" do
    root = ScriptureCircles::Publish.call(
      person: @other_member,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Quelle aide pouvons-nous trouver dans ce passage ?" }
    )
    ScriptureCircles::ConversationVotes::Cast.call(
      person: @author, conversation_root_id: root.id, direction: "up"
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    conversation_selector = "section.reader-circle-conversation[data-circle-conversation-root-id='#{root.id}']"
    assert_select "#{conversation_selector} .circle-conversation-vote[aria-label='Les conversations les plus soutenues']", count: 1
    assert_select "#{conversation_selector} form[action='#{scripture_circle_conversation_vote_path(conversation_root_id: root.id)}']", count: 1
    assert_select "#{conversation_selector} button[name='conversation_vote[direction]'][value='up'][aria-label='Faire remonter cette conversation'][aria-pressed='true']", count: 1
    assert_select "#{conversation_selector} button[name='conversation_vote[direction]'][value='down'][aria-label='Faire descendre cette conversation'][aria-pressed='false']", count: 1
    assert_select "#{conversation_selector} output.circle-conversation-vote-score[aria-label='Score : 1']", text: "1", count: 1
  end

  test "shows compact labeled votes on replies without changing the conversation score" do
    root = ScriptureCircles::Publish.call(
      person: @other_member,
      reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Comment garder cette parole en mémoire ?" }
    )
    reply = ScriptureCircles::Publish.call(
      person: @other_member,
      reference: "ot/ps/52",
      attributes: { kind: "reply", locale: "fr", parent_id: root.id, body: "Je la relis avant de commencer ma journée." }
    )
    ScriptureCircles::PostVotes::Cast.call(person: @author, post_id: reply.id, direction: "up")
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select "#circle-post-#{reply.id} .circle-post-vote[aria-label='Utilité de cette réponse']" do
      assert_select "form[action='#{scripture_circle_post_vote_path(post_id: reply.id)}']", count: 1
      assert_select "button[name='post_vote[direction]'][value='up'][aria-label='Soutenir cette réponse'][aria-pressed='true']", count: 1
      assert_select "button[name='post_vote[direction]'][value='down'][aria-label='Faire descendre cette réponse'][aria-pressed='false']", count: 1
      assert_select "output[aria-label='Score : 1']", text: "1", count: 1
    end
    assert_equal 0, root.reload.conversation_vote_score
  end

  test "keeps an anonymous author visible only to that author" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: {
        kind: "question", locale: "fr", body: "Une parole partagée sans nom.",
        author_visibility: "anonymous_to_ward"
      }
    )

    sign_in_person(@other_member)
    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#circle-post-#{post.id} .circle-message-author strong", text: "Un membre de ta rama"
    assert_select "#circle-post-#{post.id} .circle-avatar", count: 1
    assert_select "#circle-post-#{post.id} .circle-avatar img", count: 0
    assert_select "body", text: @author.display_name, count: 0
    assert_select "#circle-post-#{post.id} .circle-message-author small", text: /Aujourd’hui.*Psaume 52/

    sign_in_person(@author, token: "author-own-view")
    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#circle-post-#{post.id} .circle-message-author strong", text: "Toi"
    assert_select "#circle-post-#{post.id} .circle-message-author small", text: /Aujourd’hui.*Publiée anonymement/
  end

  test "author can choose whether an existing message remains anonymous" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: {
        kind: "question", locale: "fr", body: "Je pourrai signer ce message plus tard.",
        author_visibility: "anonymous_to_ward"
      }
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#edit-post-#{post.id} input[type='radio'][name='post[author_visibility]'][value='anonymous_to_ward'][checked]", count: 1

    patch scripture_circle_post_path(post), params: { post: { body: post.body, author_visibility: "named" } }

    assert_response :redirect
    assert_predicate post.reload, :named?
    assert_equal "anonymity_changed", post.latest_revision.change_kind
  end

  test "opens a selection-bound circle draft and keeps the chosen passage with the published message" do
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".scripture-selection-bar[aria-label='Actions sur la sélection'] button[data-action*='scripture-room#discussSelection']", text: "En parler"
    assert_select "form.reader-circle-compose-form[data-scripture-room-target='circleComposer']" do
      assert_select "input[name='post[start_verse]'][data-scripture-room-target='circleSelectionStart']"
      assert_select "input[name='post[end_verse]'][data-scripture-room-target='circleSelectionEnd']"
      assert_select "input[name='post[selected_text]'][data-scripture-room-target='circleSelectionText']"
      assert_select "input[name='post[selected_verses]'][data-scripture-room-target='circleSelectionVerses']"
      assert_select "aside.reader-circle-selection-context[hidden][data-scripture-room-target='circleSelectionContext']"
      assert_select "button.reader-circle-verse-picker-trigger[data-action*='scripture-room#toggleManualVersePicker'][aria-controls='circle-manual-verse-picker']", text: "Verset"
      assert_select "section#circle-manual-verse-picker[hidden] input#circle-manual-verse-input[placeholder='17, 19, 21-23']"
    end

    post scripture_circle_posts_path, params: { post: {
      reference: "ot/ps/52", kind: "reflection", locale: "fr",
      body: "Je veux m’arrêter sur cette vérité aujourd’hui.",
      start_verse: 3, end_verse: 6, selected_verses: "3, 5-6",
      selected_text: "Tu aimes le mal plutôt que le bien, tu aimes le mensonge plutôt que la vérité."
    } }

    assert_response :redirect
    created_post = @author.scripture_circle_posts.order(:id).last
    assert_equal 3, created_post.start_verse
    assert_equal 6, created_post.end_verse
    assert_equal "3, 5-6", created_post.selected_verses
    assert_equal "Tu aimes le mal plutôt que le bien, tu aimes le mensonge plutôt que la vérité.", created_post.selected_text
    assert_predicate created_post, :named?

    follow_redirect!

    assert_select "#circle-post-#{created_post.id} .circle-message-anchor", text: "Psaume 52:3, 5–6"
    assert_select "#circle-post-#{created_post.id} .circle-message-passage", count: 0

    get scripture_path("ot/ps/52", locale: "fr", circle_post: created_post.id)

    assert_response :success
    assert_select "#reader-detail-circle-post-#{created_post.id} .circle-message-passage", text: /Tu aimes le mal plutôt que le bien/
  end

  test "deep links to a visible conversation that has fallen outside the newest preview" do
    target = create_circle_post(kind: "question", body: "Une question plus ancienne qui mérite une réponse.")
    reply = create_circle_post(kind: "reply", parent: target, body: "Voici une réponse qui appartient à cette conversation.")
    21.times do |index|
      create_circle_post(kind: "reflection", body: "Partage récent #{index}.")
    end
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr", circle_post: target.id)

    assert_response :success
    assert_select "[data-scripture-room-initial-panel='read'][data-scripture-room-initial-circle='true']", count: 1
    assert_select "section#reader-circle.reader-circle-panel", count: 1
    assert_select "[data-circle-focus-post-id='#{target.id}']", count: 1
    assert_select "#circle-post-#{target.id}[data-circle-focus-target][tabindex='-1']", count: 1
    assert_select "#circle-post-#{target.id}", text: /question plus ancienne/
    assert_select "#circle-post-#{reply.id}", text: /réponse qui appartient/
  end

  test "does not reveal a nonvisible circle deep-link target" do
    target = create_circle_post(kind: "question", body: "Cette phrase ne doit jamais sortir de sa cible.")
    target.update!(status: "author_deleted", deleted_at: Time.current)
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr", circle_post: target.id)

    assert_response :success
    assert_select "[data-circle-focus-unavailable='true']", count: 1
    assert_select ".reader-circle-panel [data-circle-focus-unavailable]", count: 1
    assert_select "#circle-post-#{target.id}", count: 0
    assert_select "body", text: /Cette phrase ne doit jamais sortir de sa cible\./, count: 0
    assert_select ".reader-circle-panel [data-circle-focus-unavailable] a.reader-text-action", text: "Le cercle"
  end

  test "keeps a community-masked message as a reversible trace" do
    target = create_circle_post(kind: "question", body: "Cette phrase reste dans l’historique de la rama.")
    target.update!(status: "community_censored")
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr", circle_post: target.id)

    assert_response :success
    assert_select "#circle-post-#{target.id} .circle-tombstone", text: "Message masqué par la communauté."
    assert_select "#circle-post-#{target.id} .circle-masked-message summary", text: "Afficher quand même"
    assert_select "#circle-post-#{target.id} .circle-masked-message p", text: /reste dans l’historique/
  end

  test "keeps an open moderation proposal compact in the reader overview" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Corps confidentiel du message soumis au vote." }
    )
    proposal = open_moderation_vote(post, reason_key: "uncharitable")
    ScriptureCircles::Moderations::CastBallot.call(person: @author, proposal_id: proposal.id, choice: "yes")
    assert_includes Scriptures::ReaderScreen.call(person: @author, reference: "ot/ps/52", locale: "fr").circle_posts, post
    sign_in_person(@author)

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select ".reader-circle-panel", count: 1
    assert_select "#circle-post-#{post.id} .reader-circle-moderation-summary", text: /1 vote/
    assert_select "#circle-post-#{post.id} .circle-vote-card", count: 0
    assert_select "#circle-post-#{post.id} .circle-vote-message", count: 0
    assert_select "#circle-post-#{post.id}", text: /Corps confidentiel du message soumis au vote\./, count: 0
    assert_select ".reader-circle-moderation-state", count: 0

    get scripture_path("ot/ps/52", circle: 1, circle_post: post.id, locale: "fr")

    assert_response :success
    assert_select "#reader-detail-circle-post-#{post.id} .circle-vote-card", count: 1
    assert_select "#reader-detail-circle-post-#{post.id} .circle-vote-message", text: /Corps confidentiel du message soumis au vote\./
    assert_select "#reader-detail-circle-post-#{post.id} .circle-vote-actions button", count: 2
  end

  test "records reports without opening a vote until the third independent member" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Message à examiner avec une procédure calme." }
    )
    reporter_two = Person.create!(ward: @ward, given_name: "Noémie", avatar_key: "colibri", locale: "fr")
    reporter_three = Person.create!(ward: @ward, given_name: "Lucas", avatar_key: "loro", locale: "fr")

    [ @other_member, reporter_two ].each_with_index do |reporter, index|
      sign_in_person(reporter, token: "report-device-#{index}")
      post scripture_circle_moderation_reports_path(post_id: post.id), params: {
        report: { reason_key: "uncharitable", reason_details: "À relire avec bienveillance." }
      }
      assert_response :redirect
      assert_equal "visible", post.reload.status
      assert_equal index + 1, post.scripture_circle_moderation_reports.count
    end

    sign_in_person(reporter_three, token: "report-device-3")
    post scripture_circle_moderation_reports_path(post_id: post.id), params: {
      report: { reason_key: "uncharitable" }
    }

    assert_response :redirect
    assert_equal "vote_open", post.reload.status
    assert_equal 3, post.scripture_circle_moderation_reports.distinct.count(:reporter_person_id)
    assert_equal 1, post.scripture_circle_moderation_proposals.open.count
  end

  test "forged cross-ward circle and live-results requests reveal nothing" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Message réservé à la paroisse." }
    )
    proposal = open_moderation_vote(post, reason_key: "off_topic")
    outsider_ward = extra_ward(72, scripture_circle_mode: "active")
    outsider = Person.create!(ward: outsider_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    sign_in_person(outsider, token: "outsider-device")

    get scripture_circle_path(reference: "ot/ps/52")
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select ".circle-message-body", text: /Message réservé/, count: 0
    assert_select ".circle-vote-message", text: /Message réservé/, count: 0
    assert_select "body", text: /Message réservé à la paroisse\./, count: 0

    get scripture_circle_moderation_results_path(proposal_id: proposal.id), as: :json
    assert_response :forbidden

    patch scripture_circle_post_path(post), params: { post: { body: "Intrusion" } }
    assert_response :redirect
    assert_equal "Message réservé à la paroisse.", post.reload.body
  end

  test "profile publications are visible to the owner and current ward but not another ward" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "question", locale: "fr", body: "Que fait grandir cette parole en nous ?", anonymous: false }
    )
    anonymous_post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: {
        kind: "question", locale: "fr", body: "Cette parole reste anonyme hors de mon profil.",
        author_visibility: "anonymous_to_ward"
      }
    )

    sign_in_person(@other_member)
    get player_scripture_circle_posts_path(@author, locale: "fr")
    assert_response :success
    assert_select ".scripture-profile-post", text: /Que fait grandir/
    assert_select "body", text: /Cette parole reste anonyme/, count: 0
    assert_select ".scripture-profile-post strong", text: "Psaume 52"

    outsider_ward = extra_ward(73, scripture_circle_mode: "active")
    outsider = Person.create!(ward: outsider_ward, given_name: "Autre", avatar_key: "delfin", locale: "fr")
    sign_in_person(outsider, token: "other-ward-device")
    get player_scripture_circle_posts_path(@author)
    assert_response :success
    assert_select ".scripture-profile-post", count: 0
    assert_select "body", text: /Que fait grandir/, count: 0

    sign_in_person(@author, token: "author-device")
    get player_scripture_circle_posts_path(@author)
    assert_response :success
    assert_select ".scripture-profile-post", text: /Que fait grandir/
    assert_select ".scripture-profile-post", text: /Cette parole reste anonyme/
    assert_select "form[action='#{scripture_circle_post_path(post)}']"
    assert_select "form[action='#{scripture_circle_post_path(anonymous_post)}']"
  end

  private

    def mark_payload
      {
        reference: "ot/ps/52", locale: "fr", anchor_scope: "passage",
        start_verse: 3, start_offset: 0, end_verse: 3, end_offset: 18,
        selected_text: "Tu aimes le mal", visual_style: "highlight", color_key: "gold",
        note_body: "Ce passage reste avec moi"
      }
    end

    def create_circle_post(kind:, body:, parent: nil, person: @other_member)
      thread = @ward.scripture_circle_threads.find_or_create_by!(reference: "ot/ps/52")
      thread.scripture_circle_posts.create!(
        ward: @ward,
        person:,
        parent:,
        kind:,
        locale: "fr",
        body:,
        author_visibility: "named"
      )
    end

    def open_moderation_vote(post, reason_key:)
      reporter_two = Person.create!(ward: @ward, given_name: "Noémie", avatar_key: "colibri", locale: "fr")
      reporter_three = Person.create!(ward: @ward, given_name: "Lucas", avatar_key: "loro", locale: "fr")
      ScriptureCircles::Moderations::Report.call(person: @other_member, post_id: post.id, reason_key:)
      ScriptureCircles::Moderations::Report.call(person: reporter_two, post_id: post.id, reason_key:)
      ScriptureCircles::Moderations::Report.call(person: reporter_three, post_id: post.id, reason_key:).proposal
    end

    def sign_in_person(person, token: "reader-device")
      person.person_devices.find_or_create_by!(device_token: token)
      set_signed_cookie(:noche_device, token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)
    end

    def set_signed_cookie(name, value)
      signed_value = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
      uri = URI("http://#{host}/")
      cookies.merge("#{name}=#{Rack::Utils.escape(signed_value)}; path=/", uri)
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
