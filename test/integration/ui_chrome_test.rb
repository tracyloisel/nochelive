require "test_helper"

class UiChromeTest < ActionDispatch::IntegrationTest
  test "home page ships the white motion chrome" do
    get root_path
    assert_response :success
    assert_select 'meta[name="view-transition"][content="same-origin"]'
    assert_select 'meta[name="theme-color"][content="#f6f3ec"]'
    assert_select 'meta[name="viewport"][content*="interactive-widget=resizes-content"]'
    assert_select "body[data-controller~=press][data-controller~=motion]"
    assert_select "body.is-kid"
    assert_includes response.body, "window.NocheSfx"
    assert_includes response.body, "timer_tension"
    assert_includes response.body, "/sfx/tick.mp3"
    assert_select "audio#noche_sfx_gate[playsinline]"
    assert_select "audio#noche_sfx_gate[src='/sfx/tick.mp3']"
    assert_select "#street_world"
    assert_select ".street-hub-lockup-star"
    assert_select ".home-paper", count: 0
    assert_select "nav.home-menu"
    assert_select ".home-menu-btn .picto-menu"
    assert_select ".home-menu-btn .picto-cross"
    assert_select ".chrome-drawer .home-menu-nav"
    assert_select ".chrome-face.is-guest"
    assert_select ".chrome-face.is-guest .picto-person"
    assert_select ".home-menu-kicker", text: I18n.t("home.ward_menu")
    assert_select ".home-menu-kicker", text: I18n.t("church.menu")
    assert_select ".home-menu-kicker", text: I18n.t("home.about_menu")
    assert_select ".home-menu-kicker", text: I18n.t("home.program"), count: 0
    assert_select ".chrome-drawer a.home-menu-row[href=?]", jugar_path, text: I18n.t("street.menu_play")
    assert_select ".chrome-drawer a.home-menu-row[href=?]", nights_path, text: I18n.t("home.nights_menu")
    assert_select ".chrome-drawer a.home-menu-row[href=?]", search_path
    assert_select ".chrome-drawer a.home-menu-row[href=?]", street_history_path
    assert_select ".chrome-drawer .place-input", count: 0
    assert_select ".chrome-drawer .code-input"
    assert_select "details.home-code summary", text: I18n.t("home.night_code")
    assert_select ".story-ticks", count: 0
    assert_select ".street-card.is-pack"
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: I18n.t("chrome.sound_on")
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-opt .picto-flag-es"

    start_street_jugar!
    get jugar_path
    assert_select "#street_quiz.play-reel.is-quiz.is-street"
    assert_select "a.home-menu-row[href=?]", root_path, text: I18n.t("street.ceremony_back_map")
    assert_select ".play-sheet-grip", count: 0
    assert_select ".street-quiz-head"
    assert_select ".street-quiz-apex"
    assert_select ".street-quiz-card"
    assert_select ".street-level-rail"
    assert_select "#street_quiz .btn.btn-gold", count: 0
    assert_select ".home-menu.is-split .chrome-face"
    assert_select ".home-menu.is-split .home-menu-btn"
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: I18n.t("chrome.sound_on")
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-tools .mute", count: 0
  end

  test "every named cue is a public mp3" do
    Sfx::CUES.each do |name|
      get "/sfx/#{name}.mp3"
      assert_response :success, "missing /sfx/#{name}.mp3"
      assert_match %r{audio/(mpeg|mp3)}, response.media_type
    end
  end

  test "every street quiz still is a public jpeg" do
    QuizDefinition.catalog.all_questions.each do |question|
      get "/media/#{question.presentation['image']}"
      assert_response :success, "missing #{question.presentation['image']}"
      assert_match %r{image/jpeg}, response.media_type
    end
  end

  test "design tokens and motion live in the stylesheet" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, ".sfx-gate"
    assert_includes css, ".mute > * { grid-area: 1 / 1; }"
    assert_includes css, ".chrome-tools"
    assert_includes css, ".scripture-veil[hidden]"
    assert_includes css, "--paper:"
    assert_includes css, ".street-live-dot"
    assert_includes css, "--space-4:"
    assert_includes css, "--dur-press:"
    assert_includes css, "@keyframes ripple"
    assert_includes css, "@keyframes arrive"
    assert_includes css, ".toast-slot"
    assert_includes css, "@keyframes banner-glide"
    assert_includes css, "banner-glide 4.4s"
    assert_includes css, "@view-transition"
    assert_includes css, "prefers-reduced-motion"
    assert_includes css, "fieldset.place"
    assert_includes css, "p.place"
    assert_includes css, ".picture-card"
    assert_includes css, ".choice-mark"
    assert_includes css, ".quiz-meta"
    assert_includes css, ".play-reel.is-street.is-quiz .quiz-bar .word"
    assert_includes css, ".choice-token"
    assert_includes css, ".order-chip"
    assert_includes css, ".picto"
    assert_includes css, ".play-reel"
    assert_includes css, ".ward-grid"
    assert_includes css, ".place-input"
    assert_includes css, ".home-menu"
    assert_includes css, ".home-menu-row"
    assert_includes css, ".home-menu-nav"
    assert_includes css, ".chrome-drawer"
    assert_includes css, ".chrome-face.quiet-link,\n.home-menu-btn.quiet-link"
    assert_includes css, "--street-hub-col:"
    assert_includes css, "--street-hub-inset:"
    assert_includes css, "--chrome-head:"
    assert_includes css, "--type-min:"
    assert_includes css, "--street-play-col:"
    assert_includes css, "--street-ceremony-col:"
    assert_includes css, ":root, body {"
    refute_includes css, "body.is-street-hub:has(#street_world.is-profile-gate)"
    refute_includes css, ".street-map-path-title::after"
    assert_includes css, ".rama-nights"
    assert_includes css, ".home-paper"
    assert_includes css, ".play-reel.is-street"
    assert_includes css, "color-mix(in srgb, var(--temple-marble, var(--paper)) 94%, white)"
    motion = Rails.root.join("app/javascript/controllers/motion_controller.js").read
    assert_includes motion, 'target === "street_quiz"'
    assert_includes motion, "wrapStreet"
    assert_includes css, "view-transition-name: street-sheet"
    assert_includes css, "view-transition-name: street-score"
    assert_includes css, ".play-reel.is-street .street-score"
    assert_includes css, ".play-reel.is-street.is-quiz .play-sheet-body"
    assert_includes css, "padding: calc(var(--space-5) + var(--space-1)) var(--space-5)"
    assert_includes css, ".street-world"
    assert_includes css, ".street-card"
    assert_includes css, "@keyframes pack-pulse"
    assert_includes css, "street-sheet-rise"
    assert_includes css, ".hall-sheet"
    assert_includes css, ".hall-sheet.charter-sheet"
    assert_includes css, ".play-timer"
    assert_includes css, ".timer-halo"
    assert_includes css, "animation: timer-halo-beat 0.76s linear both;"
    assert_includes css, "animation: timer-halo-beat-hot 0.64s linear both;"
    assert_includes css, "@keyframes timer-halo-beat {"
    assert_includes css, "@keyframes timer-halo-beat-hot {"
    assert_includes css, "0%, 4% { opacity: 1; }"
    assert_includes css, "22% { opacity: 0.4; }"
    assert_includes css, "32% { opacity: 0.48; }"
    assert_includes css, "18% { opacity: 0.18; }"
    assert_includes css, "28% { opacity: 0.26; }"
    assert_includes css, "100% { opacity: 0.26; }"
    assert_includes css, "100% { opacity: 0.1; }"
    assert_includes css, ".timer-halo { animation: none !important; }"
    refute_includes css, "timer-halo-beat 0.26s"
    refute_includes css, "timer-halo-beat-hot 0.14s"
    refute_includes css, "timer-halo-beat 0.82s"
    refute_includes css, "0% { opacity: 0.38; }"
    refute_includes css, "animation-duration: 0.68s;"
    assert_includes css, ".street-praise"
    assert_includes css, "container-name: street-shot"
    assert_includes css, "clamp(1.5rem, 9cqi, 2.55rem)"
    refute_includes css, "clamp(3.9rem, 20vw, 6.1rem)"
    refute_includes css, "scale(1.28)"
    assert_includes css, "body[class*=\"is-fx-\"]::after { display: none; }"
    assert_includes css, ".story-close"
    assert_includes css, ".story-ticks"
    assert_includes css, ".story-audience"
    assert_includes css, ".story-score"
    assert_includes css, ".is-kid .story-audience.btn"
    assert_includes css, ".story-night"
    assert_includes css, ".night-quiz-head"
    assert_includes css, "--story-type:"
    assert_includes css, "--story-type-soft:"
    assert_includes css, "--story-shadow:"
    assert_includes css, "--scrim-top:"
    assert_includes css, "--scrim-bottom:"
    assert_includes css, "--scrim-board:"
    assert_includes css, "rgba(28, 25, 21, 0.9)"
    assert_includes css, "rgba(28, 25, 21, 0.42)"
    assert_includes css, ".watch-caption,\n.stage-caption {\n  background: var(--scrim-bottom);"
    assert_includes css, "background: var(--scrim-board);"
    assert_includes css, "body.is-watch .chrome-tools .mute { display: none; }"
    refute_includes css, "linear-gradient(180deg, var(--paper) 0%, transparent 28%)"
    assert_includes css, "--sky:"
  end

  test "watch screen is a still-first cinema board" do
    get night_watch_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-watch.is-kid"
    assert_select ".watch.is-board"
    assert_select ".watch-shot"
    assert_select ".watch-chrome .watch-mark"
    assert_select ".watch-chrome .presence-stat", count: 0
    assert_select ".watch-chrome .live", count: 0
    assert_select ".watch-corner", count: 4
    assert_select ".watch-board .score-strip"
    assert_select ".challenge-story[src='/media/stories/salomon_wisdom.jpg']"
    assert_select ".cheer-dock", count: 0
  end

  test "name screen is a paper hall without Story costume" do
    get night_name_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "h1", text: /llama/
    assert_select ".picture-card", count: 2
    assert_select ".picto-sofa"
    assert_select ".picto-house"
    assert_select "a.quiet-link", text: /Soy el presentador/
    assert_select "#night_join.hall-paper"
    assert_select ".hall-sheet"
    assert_select ".play-reel", count: 0
    assert_select ".play-shot", count: 0
    assert_select ".play-sheet-grip", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".story-close", count: 0
    assert_select ".picto-btn", count: 0
    assert_select "#night_join"
  end

  test "presenter console is a live reel not a form" do
    sign_in_presenter(game_sessions(:david))
    get presenter_console_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-presenter"
    assert_select ".console.is-stage"
    assert_select ".stage-shot"
    assert_select ".stage-dock"
    assert_select ".code-chip", text: "DAVID"
    assert_select ".challenge-story[src='/media/stories/salomon_wisdom.jpg']"
    assert_select ".story-close"
    assert_select ".console.is-stage[data-controller=story]"
    assert_select ".desk-sheet"
    assert_select ".desk-sheet[data-sheet-peek-ratio-value='0.26']"
    assert_select ".desk-tabs"
    assert_select ".desk-board[aria-label=Marcador]"
    assert_select ".desk-team"
    assert_select ".stage-dock-main .btn-gold", count: 1
    assert_select ".stage-more", text: /Lista/
    assert_select ".stage-rail", count: 0
    assert_not_includes response.body, "Remoto: grado"
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, ".stage-dock"
    assert_includes css, ".stage-shot"
    assert_includes css, ".code-chip"
    assert_includes css, ".desk-team"
    assert_includes css, ".desk-tabs"
    assert_includes css, ".desk-mark"
    assert_includes css, "--desk-radius:"
  end

  test "finished presenter keeps the still in the shot" do
    sign_in_presenter(game_sessions(:cerrada))
    get presenter_console_path(game_sessions(:cerrada).code)
    assert_response :success
    assert_select ".stage-shot .challenge-story"
    assert_select ".stage-shot .ceremony", count: 0
    assert_select ".desk-sheet .ceremony", text: /gana la noche/
    assert_select ".story-ticks", count: 0
    assert_select ".play-sheet-grip", count: 0
  end
end
