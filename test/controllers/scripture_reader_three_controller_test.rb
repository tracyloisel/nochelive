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
    assert_select ".reader-chapter-history", text: /v\.4/
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

  test "opens on the chapter alone and keeps reading companions behind an explicit choice" do
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
    assert_select ".reader-panel-trigger[data-scripture-room-target='marksTrigger'][aria-controls='reader-companion'][aria-label='Ouvrir mes repères'] svg.picto-bookmark", count: 1
    assert_select ".reader-panel-trigger[data-scripture-room-target='circleTrigger'][aria-controls='reader-companion'][aria-label='Ouvrir le cercle'] svg.picto-conversation", count: 1
    assert_select "dialog#reader-companion-picker", count: 0

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select ".reader-companion[hidden]", count: 0
    assert_select ".reader-circle-panel", text: /Cette réflexion doit rester discrète/
    assert_select ".reader-return-to-reading", text: /Retour au chapitre/
  end

  test "uses a compact accessible circle composer and returns to the confirmed message" do
    existing_post = ScriptureCircles::Publish.call(
      person: @other_member, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Cette parole me donne de la patience." }
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "div.circle-compose-card[data-circle-composer-shell]" do
      assert_select "summary", count: 0
      assert_select "textarea#circle-post-body", count: 1
      assert_select "button.circle-composer-secondary", count: 0
    end
    assert_select "details.circle-compose-card", count: 0
    assert_select ".reader-circle-panel .reader-companion-heading-copy", count: 0
    assert_select ".reader-circle-panel .reader-companion-heading > h2", text: "Le cercle"
    assert_select "form.circle-compose-form[data-circle-composer='true'][data-circle-composer-kind='post']"
    assert_select "form.circle-compose-form input[type='checkbox'][name='post[anonymous]'][checked]", count: 1
    assert_select "#circle-post-body[aria-describedby~='circle-post-counter']"
    assert_select "button[data-circle-submit]", text: /Publier/
    assert_select "#circle-post-#{existing_post.id} details.circle-reply-composer[data-circle-composer-shell]"
    assert_select "#reply-post-#{existing_post.id}-body[aria-describedby~='reply-post-#{existing_post.id}-counter']"
    assert_select "#circle-post-#{existing_post.id} input[type='checkbox'][name='post[anonymous]'][checked]", count: 1

    post scripture_circle_posts_path, params: { post: {
      reference: "ot/ps/52", kind: "reflection", locale: "fr", body: "Je veux garder cette parole près de moi aujourd’hui."
    } }

    assert_response :redirect
    assert_nil flash[:alert], flash[:alert]
    assert_match(/circle_event=published/, response.location)
    created_post = @author.scripture_circle_posts.order(:id).last
    assert_redirected_to scripture_path("ot/ps/52", locale: "fr", circle: 1, circle_post: created_post.id, circle_event: "published")

    follow_redirect!

    assert_select "[data-circle-event='published'][data-circle-event-post-id='#{created_post.id}']"
    assert_select "#circle-post-#{created_post.id}[data-circle-message-state='new'][tabindex='-1']"
    assert_select "#circle-post-#{created_post.id} .circle-message-author strong", text: "Toi"
    assert_select "#circle-post-#{created_post.id} .circle-message-author small", text: /Anonyme pour le cercle/
    assert_select "[data-circle-send-status]", text: /rejoint|joined|unido|entrou/i
  end

  test "keeps an anonymous author visible only to that author" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Une parole partagée sans nom." }
    )

    sign_in_person(@other_member)
    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#circle-post-#{post.id} .circle-message-author strong", text: "Anonyme"
    assert_select "#circle-post-#{post.id} .circle-avatar img", count: 0
    assert_select "body", text: @author.display_name, count: 0

    sign_in_person(@author, token: "author-own-view")
    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#circle-post-#{post.id} .circle-message-author strong", text: "Toi"
    assert_select "#circle-post-#{post.id} .circle-message-author small", text: /Anonyme pour le cercle/
  end

  test "author can choose whether an existing message remains anonymous" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Je pourrai signer ce message plus tard." }
    )
    sign_in_person(@author)

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select "#edit-post-#{post.id} input[type='checkbox'][name='post[anonymous]'][checked]", count: 1

    patch scripture_circle_post_path(post), params: { post: { body: post.body, anonymous: "0" } }

    assert_response :redirect
    assert_not post.reload.anonymous?
    assert_equal "anonymity_changed", post.latest_revision.change_kind
  end

  test "opens a selection-bound circle draft and keeps the chosen passage with the published message" do
    sign_in_person(@author)

    get scripture_path("ot/ps/52", locale: "fr")

    assert_response :success
    assert_select ".scripture-selection-bar[aria-label='Actions sur la sélection'] button[data-action*='scripture-room#discussSelection']", text: "En parler"
    assert_select "form.circle-compose-form[data-scripture-room-target='circleComposer']" do
      assert_select "input[name='post[start_verse]'][data-scripture-room-target='circleSelectionStart']"
      assert_select "input[name='post[end_verse]'][data-scripture-room-target='circleSelectionEnd']"
      assert_select "input[name='post[selected_text]'][data-scripture-room-target='circleSelectionText']"
      assert_select "aside.circle-selection-context[hidden][data-scripture-room-target='circleSelectionContext']"
    end

    post scripture_circle_posts_path, params: { post: {
      reference: "ot/ps/52", kind: "reflection", locale: "fr",
      body: "Je veux m’arrêter sur cette vérité aujourd’hui.",
      start_verse: 3, end_verse: 3,
      selected_text: "Tu aimes le mal plutôt que le bien, tu aimes le mensonge plutôt que la vérité."
    } }

    assert_response :redirect
    created_post = @author.scripture_circle_posts.order(:id).last
    assert_equal 3, created_post.start_verse
    assert_equal 3, created_post.end_verse
    assert_equal "Tu aimes le mal plutôt que le bien, tu aimes le mensonge plutôt que la vérité.", created_post.selected_text
    assert_predicate created_post, :anonymous?

    follow_redirect!

    assert_select "#circle-post-#{created_post.id} .circle-message-passage", text: /Tu aimes le mal plutôt que le bien/
  end

  test "renders an open vote with its proposed message for same-ward voters" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Corps confidentiel du message soumis au vote." }
    )
    proposal = ScriptureCircles::Moderations::Propose.call(
      person: @other_member, post_id: post.id, reason_key: "uncharitable"
    )
    ScriptureCircles::Moderations::CastBallot.call(person: @author, proposal_id: proposal.id, choice: "yes")
    assert_includes Scriptures::ReaderScreen.call(person: @author, reference: "ot/ps/52", locale: "fr").circle_posts, post
    sign_in_person(@author)

    get scripture_path("ot/ps/52", circle: 1, locale: "fr")

    assert_response :success
    assert_select ".reader-circle-panel", text: /#{Regexp.escape(@ward.name)}/
    assert_select "#circle-post-#{post.id} .circle-vote-card"
    assert_select "#circle-post-#{post.id}", text: /Résultats en direct/
    assert_select "#circle-post-#{post.id} .circle-vote-message-label", text: "Message soumis au vote"
    assert_select "#circle-post-#{post.id} .circle-vote-message", text: /Corps confidentiel du message soumis au vote\./
    assert_select "#circle-post-#{post.id} .circle-vote-actions button", count: 2
    assert_select "#circle-post-#{post.id} form[action='#{scripture_circle_post_path(post)}']", count: 1
  end

  test "forged cross-ward circle and live-results requests reveal nothing" do
    post = ScriptureCircles::Publish.call(
      person: @author, reference: "ot/ps/52",
      attributes: { kind: "reflection", locale: "fr", body: "Message réservé à la paroisse." }
    )
    proposal = ScriptureCircles::Moderations::Propose.call(
      person: @other_member, post_id: post.id, reason_key: "off_topic"
    )
    outsider_ward = extra_ward(72, scripture_circle_mode: "active")
    outsider = Person.create!(ward: outsider_ward, given_name: "Visiteur", avatar_key: "delfin", locale: "fr")
    sign_in_person(outsider, token: "outsider-device")

    get scripture_circle_path(reference: "ot/ps/52")
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
      attributes: { kind: "reflection", locale: "fr", body: "Cette parole reste anonyme hors de mon profil." }
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
