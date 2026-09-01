require "test_helper"

class StreetHubControllerTest < ActionDispatch::IntegrationTest
  test "home is a short editorial sequence from real Hub content" do
    sign_in_congregation
    person = create_street_profile!
    person.ward.update!(scripture_circle_mode: "active")
    circle_thread = person.ward.scripture_circle_threads.create!(reference: "ot/ps/52")
    circle_thread.scripture_circle_posts.create!(
      ward: person.ward,
      person:,
      kind: "reflection",
      locale: I18n.locale.to_s,
      body: "Une réflexion récente de la rama."
    )
    week = create_current_hub_week!
    question = QuizDefinition.catalog.find_pack("coronas").questions.first
    add_unresolved_hub_answer!(person, question:)
    event = publish_hub_event!(title: "Atelier musical de la rama", kind: "music_activity")

    get root_path

    assert_response :success
    assert_equal %i[hero today rama_presence explore watch_frame install], hub_feed_sequence
    assert_select ".street-hub-feed[data-hub-layout='hero-rama-carousel'] > .hub-hero", count: 1
    assert_select "h1.hub-hero-title", count: 1
    assert_select ".street-hub-feed h1", count: 1
    assert_select ".street-hub-feed > .hub-today[data-today-kind='live']", count: 1
    assert_select ".street-hub-feed > section.hub-rama-carousel.hub-rama-presence", count: 1 do
      assert_select "> .hub-rama-presence__track.hub-content-rail__track[role='list']", count: 1
      assert_select ".hub-rama-card--live", count: 0
    end

    assert_select ".hub-rama-presence .hub-rama-event.is-published[href=?]", event.destination_path, count: 1 do
      assert_select "strong", text: event.title
    end
    assert_select ".hub-rama-presence__track > a.hub-rama-event--circle[role='listitem'][href=?]", scripture_circle_path, count: 1
    assert_select ".hub-explore-rail a.hub-content-card--reading.is-unread[href=?]",
      scripture_path(question.scripture.study, cite: question.scripture.cite), count: 1 do
      assert_select ".hub-content-card__copy > span", text: question.scripture.cite
      assert_select ".hub-content-card__copy > small", text: I18n.t("hub.rails.reading_to_read")
    end
    assert_select ".hub-hero .hub-play", count: 1
    assert_select ".hub-hero[data-hero-state='start'] .hub-play", text: I18n.t("hub.start_action")
    assert_select ".hub-hero .hub-slide", count: 1
    assert_select ".hub-hero .hub-voyage-nav, .hub-hero .hub-dot", count: 0
    assert_select ".hub-hero-cockpit__row > .hub-hero-progress", count: 1
    assert_select ".hub-hero-league, .hub-hero-league-panel, .hub-hero-reward, .hub-hero-step", count: 0
    assert_select ".quiz-hud-pack, .quiz-hud-progress, .quiz-hud-rail", count: 0
    assert_select ".hub-identity-empty", count: 0
    assert_hub_editorial_contract!
  end

  test "home renders every supported ward event kind with its published artwork" do
    sign_in_congregation
    create_street_profile!
    WardEvent::KINDS.each do |kind|
      event = publish_hub_event!(
        title: "Événement #{kind}",
        kind:,
        starts_at: 10.minutes.from_now
      )

      get root_path

      assert_response :success
      assert_select ".hub-rama-presence__track" do
        assert_select "> .hub-rama-event.is-published[href=?]", event.destination_path,
          text: /#{Regexp.escape(I18n.t("hub.rails.event_kinds.#{kind}"))}/, count: 1 do
          assert_select ".hub-rama-event__art img[src*='worship']", count: 1
          assert_select ".hub-rama-event__art img[src*='service-bread'], .hub-rama-event__art img[src*='rama-vigil']", count: 0
        end
      end
      assert_operator hub_rama_event_cards.size, :<=, 2
      event.destroy!
    end
  end

  test "home only exposes approved ward events and renders future cancellations without a destination" do
    sign_in_congregation
    create_street_profile!
    GameSession.where(ward: wards(:demo)).update_all(status: "finished")
    published = publish_hub_event!(title: "Collecte alimentaire publiée", starts_at: 10.minutes.from_now)
    draft = draft_hub_event!(title: "Brouillon privé", starts_at: 12.minutes.from_now)
    cancelled = publish_hub_event!(title: "Collecte annulée", starts_at: 11.minutes.from_now)
    cancelled.cancel!(actor: "Présidence de rama", reason: "La salle est indisponible", at: Time.current)
    bypass = WardEvent.create!(
      ward: wards(:demo),
      kind: "food_drive",
      title: "Annulation sans historique",
      summary: "Ne doit jamais apparaître.",
      starts_at: 2.hours.from_now,
      ends_at: 4.hours.from_now,
      location_label: "Salle paroissiale",
      destination_path: ward_profile_path(wards(:demo).code),
      artwork_path: "/media/church/worship.jpg",
      status: "cancelled",
      approved_by: "Présidence de rama",
      approved_at: Time.current,
      cancelled_by: "Présidence de rama",
      cancelled_at: Time.current,
      cancellation_reason: "Faux audit"
    )
    publish_hub_event!(ward: wards(:blank), title: "Événement de l’autre rama")

    get root_path

    assert_response :success
    assert_select ".hub-today[data-today-kind='rama_event'] .hub-today__story[href=?]", published.destination_path, count: 1 do
      assert_select "strong", text: published.title
    end
    assert_select ".hub-rama-presence .hub-rama-event.is-published[href=?]", published.destination_path, count: 0
    assert_select ".hub-rama-presence__track > article.hub-rama-event.is-cancelled[role='listitem']", count: 1 do
      assert_select "strong", text: cancelled.title
      assert_select ".hub-rama-event__cancelled", text: I18n.t("hub.rails.rama_cancelled")
      assert_select ".hub-rama-event__detail", text: cancelled.cancellation_reason
      assert_select "a", count: 0
    end
    assert_select ".hub-rama-presence", text: /#{Regexp.escape(draft.title)}/, count: 0
    assert_select ".hub-rama-presence", text: /#{Regexp.escape(bypass.title)}/, count: 0
    assert_select ".hub-rama-presence", text: /Événement de l’autre rama/, count: 0
    assert_operator hub_rama_event_cards.size, :<=, 2
  end

  test "a guest without a ward gets ward discovery without a fabricated identity or local moment" do
    create_current_hub_week!
    get root_path

    assert_response :success
    assert_equal %i[hero today rama_presence explore watch_frame install], hub_feed_sequence
    assert_select ".hub-today[data-today-kind='weekly_reading']", count: 1
    today_href = css_select(".hub-today__story").first["href"]
    assert_select ".hub-explore-rail a[href=?]", today_href, count: 0
    assert_select ".hub-rama-presence--missing", count: 1 do
      assert_select ".hub-rama-presence__action[href=?]",
        street_profile_path(quick: 1, fresh: 1, ward_next: 1), count: 1
      assert_select "h2", text: I18n.t("hub.rama.find_title")
    end
    assert_select ".hub-live--feature, .hub-rama-event, dl", count: 0
    assert_select ".hub-now", count: 0
    assert_select ".hub-identity-empty", count: 0
    assert_select ".quiz-hud.is-guest .quiz-hud-cta", count: 0
    assert_select ".hub-hero .hub-play", count: 1
    assert_hub_editorial_contract!
  end

  test "a signed-in player without a Rama keeps the editorial Home and gets one compact ward invitation" do
    person = create_street_profile!
    assert_nil person.ward
    create_current_hub_week!

    get root_path

    assert_response :success
    assert_equal %i[hero today rama_presence explore watch_frame install], hub_feed_sequence
    assert_select ".quiz-hud:not(.is-guest) .quiz-hud-name", text: person.given_name, count: 1
    assert_select ".hub-today[data-today-kind='weekly_reading']", count: 1
    today_href = css_select(".hub-today__story").first["href"]
    assert_select ".hub-explore-rail a[href=?]", today_href, count: 0
    assert_select ".hub-rama-presence--missing", count: 1 do
      assert_select ".hub-rama-presence__action[href=?]", search_path(cambiar: 1), count: 1
    end
    assert_select ".hub-rama-event, .hub-live--feature, .hub-identity-empty", count: 0
    assert_hub_editorial_contract!
  end

  test "the new Hub copy is available in all four supported locales" do
    %w[es fr en pt-BR].each do |locale|
      %w[challenge_incoming challenge_active challenge_accept challenge_open challenge_due].each do |key|
        assert I18n.exists?("hub.now.#{key}", locale), "hub.now.#{key} is missing in #{locale}"
      end
      %w[title date_range].each do |key|
        assert I18n.exists?("hub.today.#{key}", locale), "hub.today.#{key} is missing in #{locale}"
      end
      %w[live live_upcoming daily_discovery expedition weekly_reading weekly_program rama_event].each do |kind|
        assert I18n.exists?("hub.today.kinds.#{kind}", locale), "hub.today.kinds.#{kind} is missing in #{locale}"
        assert I18n.exists?("hub.today.actions.#{kind}", locale), "hub.today.actions.#{kind} is missing in #{locale}"
      end
      assert I18n.exists?("hub.today.kinds.fallback", locale), "hub.today.kinds.fallback is missing in #{locale}"
      %w[fallback_title fallback_body].each do |key|
        assert I18n.exists?("hub.today.#{key}", locale), "hub.today.#{key} is missing in #{locale}"
      end
      %w[title find_kicker find_title find_body find_action circle_news_kicker circle_action circle_last_activity].each do |key|
        assert I18n.exists?("hub.rama.#{key}", locale), "hub.rama.#{key} is missing in #{locale}"
      end
      %w[kicker progress open continue dates].each do |key|
        assert I18n.exists?("hub.expedition.#{key}", locale), "hub.expedition.#{key} is missing in #{locale}"
      end
      %w[explore watch watch_open watch_card_label reading_to_read reading_in_progress reading_completed reading_card_label].each do |key|
        assert I18n.exists?("hub.rails.#{key}", locale), "hub.rails.#{key} is missing in #{locale}"
      end
      %w[next_eyebrow resume_eyebrow question_step start_action resume_action].each do |key|
        assert I18n.exists?("hub.#{key}", locale), "hub.#{key} is missing in #{locale}"
      end
    end
  end

  test "the honest fallback delegates its date to the visitor's civil clock" do
    travel_to Time.utc(1900, 1, 2, 23, 30) do
      get root_path
    end

    assert_response :success
    assert_select ".hub-today[data-today-kind='fallback'] article.hub-today__story", count: 1 do
      assert_select "time[data-controller='local-date'][hidden]", count: 1
      assert_select "a, button", count: 0
    end
  end

  test "a known ward without any linked player gets an honest player-missing state" do
    ward = wards(:blank)
    sign_in_congregation(ward)
    get root_path

    assert_response :success
    assert_equal %i[hero today watch_frame identity_empty install], hub_feed_sequence
    assert_select ".hub-rama-presence, .hub-rama-carousel, .hub-live--feature", count: 0
    assert_select ".quiz-hud.is-guest .quiz-hud-who.is-guest", count: 1
    assert_select ".hub-now", count: 0
    assert_select ".street-hub-feed > article.hub-identity-empty.is-player-missing", count: 1 do
      assert_select "> a.hub-identity-empty__action[href=?]", street_profile_path(quick: 1, fresh: 1), count: 1
    end
    assert_select ".street-hub-feed > article.hub-identity-empty.is-player-missing + .hub-install", count: 1
    assert_select ".hub-identity-empty.is-player-unselected", count: 0
    assert_hub_editorial_contract!
  end

  test "a known ward with a linked player but no current selection offers the existing profile picker" do
    sign_in_congregation
    person = create_street_profile!(name: "Profil déjà lié")
    assert person.person_devices.exists?
    cookies.delete("noche_street_person")

    get root_path

    assert_response :success
    assert_equal %i[hero today watch_frame identity_empty install], hub_feed_sequence
    assert_select ".quiz-hud.is-guest .quiz-hud-who.is-guest", count: 1
    assert_select ".street-hub-feed > article.hub-identity-empty.is-player-unselected", count: 1 do
      assert_select "> a.hub-identity-empty__action[href=?]", street_profile_path(quick: 1), count: 1
    end
    assert_select ".hub-identity-empty.is-player-missing", count: 0
    assert_select ".hub-now", count: 0
    assert_hub_editorial_contract!
  end

  test "official videos are deferred behind one lazy Home frame instead of entering the initial HTML" do
    video = publish_hub_video!(locale: I18n.locale.to_s, youtube_video_id: "watchVideo5")

    get root_path

    assert_response :success
    assert_select "img[src=?]", church_video_thumbnail_path(video.youtube_video_id), count: 0
    assert_select "turbo-frame#hub_watch_rail[loading='lazy'][src=?]",
      hub_video_highlights_path(locale: I18n.locale), count: 1 do
      assert_select ".hub-watch-rail, .hub-content-card--video", count: 0
    end
  end

  test "a recommended chapter keeps its real route and reading status in the explore rail" do
    sign_in_congregation
    person = create_street_profile!
    question = QuizDefinition.catalog.find_pack("coronas").questions.first
    2.times { add_unresolved_hub_answer!(person, question:) }
    ScriptureReadingProgress.create!(
      person:,
      locale: I18n.locale.to_s,
      reference: question.scripture.study,
      first_opened_at: 1.hour.ago,
      last_opened_at: Time.current,
      last_verse: 1,
      last_offset: 0,
      progress_ratio: 0.42
    )

    get root_path

    assert_response :success
    assert_select ".hub-explore-rail .hub-content-card--reading.is-in_progress[href=?]",
      scripture_path(question.scripture.study, cite: question.scripture.cite), count: 1 do
      assert_select ".hub-content-card__copy > span", text: question.scripture.cite
      assert_select ".hub-content-card__copy > small", text: I18n.t("hub.rails.reading_in_progress", percent: 42)
      assert_select ".hub-content-card__progress i[style*='42%']", count: 1
    end
  end

  test "a quiet ward does not fabricate a challenge when the weekly programme has no chapter card" do
    sign_in_congregation(wards(:blank))
    create_street_profile!
    week = create_current_hub_week!
    quiz = week.published_quiz
    content = quiz.content.deep_dup
    content["readings"] = [ { "study" => "not-a-scripture/chapter", "labels" => { I18n.locale.to_s => "Lecture indisponible" } } ]
    quiz.update!(content:)

    get root_path

    assert_response :success
    assert_select ".hub-explore-rail .hub-content-card--reading", count: 0
    assert_select ".hub-today[data-today-kind='weekly_program'] a.hub-today__story[href=?]",
      scripture_library_path(section: "weekly", locale: I18n.locale, unit: week.id, anchor: "cette-semaine"), count: 1
    assert_select ".hub-rama-presence, .hub-rama-event--challenge", count: 0
  end

  test "PWA utility remains hidden, non-primary, and sits at the end of the editorial programme" do
    sign_in_congregation
    person = create_street_profile!
    question = QuizDefinition.catalog.find_pack("coronas").questions.first
    add_unresolved_hub_answer!(person, question:)
    publish_hub_event!(title: "Atelier de la rama")

    get root_path

    assert_response :success
    assert_select ".street-hub-feed > article.hub-panel.hub-install--compact[hidden]", count: 1 do
      assert_select "[data-pwa-install-target~='tile'][data-pwa-install-state='idle'][aria-busy='false']"
      assert_select "button.hub-install-action[data-pwa-install-target~='action'][data-action='pwa-install#install']"
      assert_select "button.hub-install-dismiss[data-pwa-install-target~='dismiss'][data-action='pwa-install#dismissTile'][aria-label=?]", I18n.t("pwa.not_now")
      assert_select "#hub_install_status.hub-install-status[data-pwa-install-target~='status'][role='status'][aria-live='polite'][aria-atomic='true'][hidden]"
      assert_select "img[src='/apple-touch-icon.png']"
      assert_select ".hub-install-copy strong", text: I18n.t("pwa.banner_title")
      assert_select ".btn.btn-gold", count: 0
    end
    assert_equal :install, hub_feed_sequence.last
    assert_operator hub_feed_sequence.index(:install), :>, hub_feed_sequence.index(:watch_frame)
    assert_select "dialog.pwa-install-dialog[aria-labelledby='pwa_install_title'][aria-describedby='pwa_install_lede']", count: 1
  end

  test "only the current hero artwork is marked LCP" do
    get root_path, headers: { "HTTP_ACCEPT" => "text/html,image/webp" }

    assert_response :success
    manifest = JSON.parse(css_select("#noche_resource_manifest").sole.text)
    assert_equal "hub.home", manifest.fetch("context")
    assert_equal "critical", manifest.fetch("classes").fetch("media.lcp")
    assert manifest.dig("media", "lcp").present?

    high_priority_images = css_select("img[fetchpriority='high']")
    assert_equal 1, high_priority_images.size
    assert_includes high_priority_images.sole["class"], "hub-slide-still"
    lcp_source = manifest.dig("media", "lcp")
    lcp_asset = Frontend::MediaManifest.fetch(lcp_source) || Frontend::MediaManifest.fetch_path(lcp_source)
    lcp_rendered_src = lcp_asset ? lcp_asset.fetch("variants").fetch("jpeg").last.fetch("src") : lcp_source
    assert_includes css_select(".hub-slide.is-current").sole.to_html, lcp_rendered_src
    assert_select ".hub-slide.is-current img.hub-slide-still[loading='eager'][fetchpriority='high'][decoding='async']", count: 1
    assert_select "#street_world .street-world-art[loading='lazy'][fetchpriority='low']", count: 1
    assert_select ".hub-today img[fetchpriority='high'], .hub-live img[fetchpriority='high'], .hub-rama-presence img[fetchpriority='high'], .hub-explore-rail img[fetchpriority='high'], .hub-install img[fetchpriority='high']", count: 0
  end

  test "the Hero exposes one action while secondary editorial surfaces stay independent" do
    get root_path

    assert_response :success
    assert_select ".hub-hero[data-controller='hub-portal'] .hub-voyage > .hub-slide.is-current", count: 1
    assert_select ".hub-hero[data-controller~='hub-voyage'], .hub-voyage-nav, .hub-dot", count: 0
    assert_select ".hub-rama-presence--missing", count: 1
    assert_select ".hub-rama-presence[data-controller~='hub-voyage']", count: 0
    refute Rails.root.join("app/javascript/controllers/hub_voyage_controller.js").exist?
  end

  test "an open quiz is explicitly presented as the one game to resume" do
    sign_in_congregation
    create_street_profile!
    post street_pack_start_path("coronas")

    assert_response :redirect
    get root_path

    assert_response :success
    assert_select ".hub-hero[data-hero-state='resume']", count: 1 do
      assert_select ".hub-hero-continue", text: I18n.t("hub.resume_eyebrow")
      assert_select ".hub-hero-progress[aria-label=?]", I18n.t("hub.question_step", n: 1, total: 10), count: 1
      assert_select "a.hub-play[href=?]", jugar_path, text: I18n.t("hub.resume_action", n: 1)
      assert_select ".hub-slide", count: 1
    end
    assert_select ".quiz-hud-pack, .quiz-hud-progress, .quiz-hud-rail", count: 0
  end

  test "artwork selects a shared light or dark Hub markup without a user theme toggle" do
    {
      "light" => { "image" => "church/worship.jpg", "atmosphere" => "peaceful" },
      "dark" => { "image" => "quizzes/coronas/ungio_david.jpg", "atmosphere" => "solemn" }
    }.each do |mode, artwork|
      Hubs::Backdrop.entries = [
        {
          "id" => "hub-#{mode}",
          "image" => artwork.fetch("image"),
          "tags" => [ "coronas" ],
          "theme" => { "mode" => mode, "atmosphere" => artwork.fetch("atmosphere"), "accent" => "gold" }
        }
      ]

      get root_path

      assert_response :success
      assert_select "body.is-game-hub-page.is-celestial-#{mode}", count: 1
      assert_select "#street_world[data-hub-theme=?]", mode, count: 1
      assert_select "#street_world[data-hub-atmosphere=?]", artwork.fetch("atmosphere"), count: 1
      assert_select ".street-hub-feed > .hub-hero", count: 1
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "menu footer lists the three requested legal destinations" do
    get root_path

    assert_response :success
    assert_select ".hub-menu-information" do
      assert_select "a[href=?]", about_path, text: I18n.t("hub_menu.about_us")
      assert_select "a[href=?]", legal_path, text: I18n.t("hub_menu.legal")
      assert_select "a[href=?]", privacy_path, text: I18n.t("hub_menu.privacy")
    end
  end

  test "rank_up param keeps the one-time hub reward cue" do
    get root_path(rank_up: 1)

    assert_response :success
    assert_select "#street_world[data-stage-sfx-value=level_up]"
    assert_select "#street_world[data-stage-sfx-token-value^='hub:rank_up:']"
  end

  test "player HUD names the next rank instead of putting XP on the primary action" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    get root_path

    assert_select ".quiz-hud-name", text: pili.given_name
    assert_select ".quiz-hud-rank > span:first-child", text: I18n.t("ranks.guerrero")
    assert_select ".street-xp-caption, .street-rank-banner", count: 0
  end

  test "legacy camino paths redirect to the map historial anchor" do
    get "/camino"
    assert_redirected_to "/mapa#historial"

    get "/camino/historial"
    assert_redirected_to "/mapa#historial"
  end

  test "map page shows the celestial tier path and progression HUD" do
    get street_map_path
    assert_response :success
    assert_select "link[href*='pages/street_map'][data-turbo-track='dynamic']", count: 1
    assert_select "#street_world.street-map-page"
    assert_select ".mapa-header .mapa-title", text: I18n.t("street.mapa_title")
    assert_select ".mapa-mission"
    assert_select ".mapa-mission-progress[role=progressbar]"
    assert_select ".mapa-continue", text: I18n.t("hub.continue")
    assert_select ".mapa-stats-row", count: 0
    assert_select ".mapa-tabs .mapa-tab", count: 4
    assert_select ".mapa-tabs .mapa-tab[aria-selected=true]", count: 1
    assert_select ".mapa-tier[data-tier-key=debutant]"
    assert_select ".mapa-tier[data-tier-key=apprenti]"
    assert_select ".mapa-tier.is-collapsed", count: 2
    assert_select ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select ".mapa-node.is-current .mapa-node-beacon"
    assert_select ".mapa-node.is-current[aria-current=step]"
    assert_select ".mapa-node.is-locked[data-action*='click->hub-map#tapNode'] .mapa-node-lock"
    assert_select ".mapa-footer-cta[href=?]", street_leaderboard_path
    assert_select "body > .home-menu.is-hud .quiz-hud"
    assert_select "body > .navigation-dock .navigation-dock__item.is-active[href=?]", street_map_path
    assert_select "#street_world .home-menu", count: 0
    assert_select "#street_world .navigation-dock", count: 0
    assert_select "a.home-menu-adventure[href=?]", street_map_path, text: /#{Regexp.escape(I18n.t("hub_menu.adventure"))}/
    assert_select "a.home-menu-row[href=?]", street_leaderboard_path, text: I18n.t("hub_menu.leaderboard")
    assert_select "a.home-menu-row[href=?]", scripture_library_path, text: /#{Regexp.escape(I18n.t("scripture_library.title"))}/
    assert_select "a.home-menu-adventure[href=?]", street_map_path, count: 1

    page_css = Rails.root.join("app/assets/stylesheets/pages/street_map.css").read
    css = Rails.root.join("app/assets/stylesheets/application.css").read + Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read + page_css
    assert_includes page_css, ".mapa-mission {"
    assert_includes page_css, ".mapa-tabs {"
    assert_includes page_css, ".mapa-node-circle {"
    map_body = css[/body\.is-street-map-page \{[^}]+\}/m]
    refute_includes map_body, "--hud-inset"
    refute_includes map_body, "--navigation-dock-width"
    assert_includes css, "body.is-street-map-page .sky { background: none; }"
    assert_match(/\.home-menu\.is-hud \{[^}]*position: fixed;[^}]*left: 0;[^}]*right: 0;[^}]*max-width: none;[^}]*transform: none;[^}]*padding-inline: max\(clamp\(0\.9rem, 3vw, 2\.25rem\), env\(safe-area-inset-left\)\);/m, css)
    assert_match(/\.home-menu\.is-hud\.is-compact \{[^}]*left: max\(var\(--hud-floating-inset\), env\(safe-area-inset-left\)\);[^}]*right: max\(var\(--hud-floating-inset\), env\(safe-area-inset-right\)\);/m, css)
    assert_match(/\.navigation-dock \{[^}]*position: fixed;[^}]*left: max\(0\.75rem, env\(safe-area-inset-left\)\);[^}]*right: max\(0\.75rem, env\(safe-area-inset-right\)\);[^}]*width: auto;/m, css)
    assert_match(/\.street-world\.street-map-page \{[^}]*padding: calc\(6rem \+ env\(safe-area-inset-top\)\)/m, css)
    refute_includes css, "body.is-street-hub:has(.home-menu.is-hud) .street-map-page"
    refute_includes css, ".street-map-page > .home-menu"
  end

  test "complete journey remains the map landing view when expeditions are published" do
    create_current_expedition_week!

    get street_map_path

    assert_response :success
    assert_select ".mapa-mode-tab.is-active[href=?]", street_map_path(view: "journey"), count: 1
    assert_select ".mapa-mode-tab.is-active", text: /#{Regexp.escape(I18n.t("street.mapa_journey"))}/
    assert_select ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select ".mapa-expedition-carousel", count: 0
    assert_select ".mapa-expedition-hero", count: 0
  end

  test "expedition map is a distinct free-choice view over permanent packs" do
    week = create_current_expedition_week!

    get street_map_path(view: "expeditions", expedition: week.id, locale: :fr)

    assert_response :success
    assert_select ".mapa-mode-tabs .mapa-mode-tab", count: 2
    assert_select ".mapa-mode-tab.is-active", text: /#{Regexp.escape(I18n.t("street.mapa_expeditions", locale: :fr))}/
    assert_select ".mapa-expedition-carousel[role=list]", count: 1
    assert_select ".mapa-expedition-card.is-active .mapa-expedition-card__link[aria-current=page]", count: 1
    assert_select ".mapa-expedition-card__schedule", minimum: 1
    assert_select ".mapa-expedition-journey-link[href=?]", street_map_path(view: "journey"), count: 1
    assert_select ".mapa-expedition-hero h2", text: "Ça aussi, c’est dans les Psaumes"
    assert_select ".mapa-expedition-hero__badges", count: 1
    assert_select ".mapa-expedition-hero__cta", count: 1
    assert_select ".mapa-expedition-door", count: 6
    assert_select ".mapa-expedition-door form[action*='expedition=#{week.id}']", count: 6
    assert_select ".mapa-node", count: 0
  end

  test "an unknown expedition deep link falls back to the current expedition" do
    week = create_current_expedition_week!

    get street_map_path(view: "expeditions", expedition: "missing-expedition", locale: :fr)

    assert_response :success
    assert_select ".mapa-expedition-hero h2", text: "Ça aussi, c’est dans les Psaumes"
    assert_select ".mapa-expedition-card.is-active .mapa-expedition-card__link[aria-current=page]", count: 1
    assert_select ".mapa-node", count: 0
  end

  test "home presents the weekly expedition as an editorial teaser before Rama" do
    sign_in_congregation
    create_street_profile!
    week = create_current_expedition_week!

    get root_path(locale: :fr)

    assert_response :success
    assert_equal %i[hero today expedition explore watch_frame install], hub_feed_sequence
    assert_select ".street-hub-feed > .hub-expedition", count: 1 do
      assert_select "h2", text: "Ça aussi, c’est dans les Psaumes"
      assert_select ".hub-expedition__copy > strong", text: "Six portes cachées"
      assert_select ".hub-expedition__copy > span", text: "Entre dans six histoires humaines."
      assert_select "time[datetime=?]", "#{week.starts_on.iso8601}/#{week.ends_on.iso8601}", count: 1
      assert_select ".hub-expedition__progress", text: I18n.t("hub.expedition.progress", done: 0, total: 6, locale: :fr), count: 1
      assert_select ".hub-expedition__cta[href=?]", street_map_path(view: "expeditions", expedition: week.id)
      assert_select "ol, li, .hub-expedition__doors", count: 0
    end
    assert_select ".hub-rama-presence", count: 0
    assert_operator hub_feed_sequence.index(:expedition), :<, hub_feed_sequence.index(:explore)
  end

  test "map page stylesheet stays off the home render path" do
    get root_path

    assert_response :success
    assert_select "link[href*='pages/street_map']", count: 0
    assert Rails.root.join("app/assets/stylesheets/pages/street_map.css").file?
  end

  test "unlock param wires packUnlock motion on a locked pack" do
    next_pack = QuizDefinition.catalog.pack_ids.second
    get street_map_path(unlock: next_pack)
    assert_response :success
    assert_select "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    assert_select "#pack-#{next_pack}.is-unlocking.is-locked"
    assert_select "#pack-#{next_pack} .mapa-node-hit", count: 0
  end

  test "unlock param on the current pack does not replay the lock" do
    current = QuizDefinition.catalog.pack_ids.first
    get street_map_path(unlock: current)
    assert_response :success
    assert_select "#pack-#{current}.is-current"
    assert_select "#pack-#{current}.is-unlocking", count: 0
    assert_select "#pack-#{current}.is-locked", count: 0
    assert_select "[data-street-motion-sequence-value='packUnlock']", count: 0
  end

  test "invalid unlock param is ignored" do
    get street_map_path(unlock: "not-a-pack")
    assert_response :success
    assert_select "[data-street-motion-sequence-value='packUnlock']", count: 0
  end

  test "finished pack is replayable without a gold node CTA" do
    sign_in_congregation
    create_street_profile!
    post street_pack_start_path("coronas")
    follow_redirect!
    run = QuizRun.open_runs.order(:id).last
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)

    get street_map_path
    assert_response :success
    assert_select ".street-world .mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select "#pack-coronas.is-finished form[action=?]", street_pack_start_path("coronas")
    assert_select "#pack-coronas.is-finished button.mapa-node-hit"
    assert_select "#pack-#{QuizDefinition.catalog.pack_ids.second}.is-current form[action=?]",
      street_pack_start_path(QuizDefinition.catalog.pack_ids.second)
    assert_select ".mapa-node.is-locked .mapa-node-hit", count: 0

    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz"
    replay = QuizRun.open_runs.order(:id).last
    assert replay
    assert_equal "coronas", replay.pack_id
    assert_not_equal run.id, replay.id
  end

  private

    def hub_feed_sequence
      css_select(".street-hub-feed > *").map do |node|
        classes = node["class"].to_s.split
        next :hero if classes.include?("hub-hero")
        next :today if classes.include?("hub-today")
        next :expedition if classes.include?("hub-expedition")
        next :rama_presence if classes.include?("hub-rama-presence")
        next :explore if classes.include?("hub-explore-rail")
        next :watch_frame if node.name == "turbo-frame" && node["id"] == "hub_watch_rail"
        next :install if classes.include?("hub-install")
        next :identity_empty if classes.include?("hub-identity-empty")

        :unexpected
      end
    end

    def assert_hub_editorial_contract!
      assert_select ".street-hub-feed > .hub-today[data-today-kind]", count: 1
      assert_select ".hub-rama-card--videos, .hub-rama-challenge-counts, .hub-now, dl", count: 0
      assert_select "turbo-frame#hub_watch_rail[loading='lazy'][src=?]",
        hub_video_highlights_path(locale: I18n.locale), count: 1
      assert_select ".street-hub-feed > nav.hub-quick-actions", count: 0
    end

    def hub_rama_event_cards
      css_select(".hub-rama-presence__track > .hub-rama-event").reject do |node|
        classes = node["class"].to_s.split
        classes.include?("hub-rama-event--circle") || classes.include?("hub-rama-event--challenge")
      end
    end

    def add_unresolved_hub_answer!(person, question:)
      run = QuizRun.create!(
        person:,
        device_digest: "hub-reading-#{SecureRandom.hex(8)}",
        pack_id: question.pack_id,
        position: 10,
        score: 0,
        status: "finished",
        opened_at: Time.current
      )
      QuizAnswer.create!(
        quiz_run: run,
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: false
      )
    end

    def publish_hub_event!(ward: wards(:demo), title:, kind: "food_drive", starts_at: 2.hours.from_now, **overrides)
      event = draft_hub_event!(ward:, title:, kind:, starts_at:, **overrides)
      event.publish!(actor: "Présidence de rama", at: Time.current)
      event
    end

    def draft_hub_event!(ward: wards(:demo), title:, kind: "food_drive", starts_at: 2.hours.from_now, **overrides)
      WardEvent.create_draft!(
        ward:,
        attributes: {
          kind:,
          title:,
          summary: "Une activité réelle publiée par la paroisse.",
          starts_at:,
          ends_at: starts_at + 2.hours,
          location_label: "Salle paroissiale",
          destination_path: ward_profile_path(ward.code),
          artwork_path: "/media/church/worship.jpg"
        }.merge(overrides),
        actor: "Présidence de rama",
        at: Time.current
      )
    end

    def publish_hub_video!(locale:, youtube_video_id:)
      ScriptureVideoLink.create!(
        reference: "ot/ps/52",
        locale:,
        youtube_video_id:,
        channel_id: ChurchVideos::Catalog.official_channel_id(locale),
        editorial_reason: "Une vidéo officielle approuvée",
        status: "published",
        position: 0,
        reviewed_by: "Équipe éditoriale",
        verified_at: Time.current,
        published_at: Time.current,
        source_url: "https://www.youtube.com/watch?v=#{youtube_video_id}"
      )
    end

    def create_current_hub_week!
      program = StudyProgram.create!(
        slug: "hub-weekly-#{SecureRandom.hex(6)}",
        title: "Viens et suis-moi #{Date.current.year}",
        year: Date.current.year + 10,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/hub-weekly"
      )
      week = program.study_units.create!(
        slug: "week-current",
        kind: "week",
        position: 1,
        title: "Cette semaine : Psaumes",
        source_url: "https://example.test/hub-weekly/current",
        starts_on: Date.current.beginning_of_week,
        ends_on: Date.current.end_of_week,
        scripture_refs: [ "Psaumes" ],
        status: "published"
      )
      content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
      week.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      week
    end

    def create_current_expedition_week!
      week = create_current_hub_week!
      week.study_quiz_versions.update_all(status: "retired")
      pack_ids = %w[
        exp_psalms_disappearing_voice exp_psalms_nameless_king
        exp_psalms_cry_stone_seek exp_psalms_house_table_city
        exp_psalms_suspended_harps exp_psalms_everything_breathes
      ]
      content = {
        "light" => { "fr" => "Le Dieu qui me relève est digne de louange." },
        "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
        "questions" => [],
        "readings" => [ { "study" => "ot/ps/102", "labels" => { "fr" => "Psaume 102" } } ],
        "expedition" => {
          "id" => "weekly-psalms",
          "title" => { "fr" => "Ça aussi, c’est dans les Psaumes" },
          "subtitle" => { "fr" => "Six portes cachées" },
          "promise" => { "fr" => "Entre dans six histoires humaines." },
          "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
          "pack_ids" => pack_ids,
          "packs" => pack_ids.map.with_index do |id, index|
            { "id" => id, "title" => { "fr" => "Porte #{index + 1}" }, "hook" => { "fr" => "Une histoire à ouvrir." } }
          end
        }
      }
      week.study_quiz_versions.create!(
        version: 2,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      week
    end
end
