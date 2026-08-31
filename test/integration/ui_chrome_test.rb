require "test_helper"

class UiChromeTest < ActionDispatch::IntegrationTest
  test "home page ships the white motion chrome" do
    get root_path
    assert_response :success
    assert_select 'meta[name="view-transition"][content="same-origin"]'
    assert_select 'meta[name="theme-color"][content="#f6f3ec"]'
    assert_select 'meta[name="viewport"][content*="interactive-widget=resizes-visual"]'
    assert_select "body[data-controller~=press][data-controller~=motion]"
    assert_select "body.is-kid"
    assert_includes response.body, "noche_sfx_catalog"
    refute_includes response.body, "timer_tension"
    assert_includes response.body, "/sfx/tick.mp3"
    assert_select "audio#noche_sfx_gate[playsinline]"
    assert_select "audio#noche_sfx_gate[src^='/sfx/tick.mp3']"
    assert_select "#street_world"
    assert_select ".hub-hero"
    assert_select ".home-paper", count: 0
    assert_select "nav.home-menu"
    assert_select ".home-menu-btn .picto-menu"
    assert_select ".chrome-drawer .is-drawer-close .picto-cross"
    assert_select ".chrome-drawer .home-menu-nav-hub"
    assert_select ".quiz-hud-who.is-guest"
    assert_select ".quiz-hud-avatar.is-guest"
    hub_mode = css_select("body").first["class"][/\bis-celestial-(light|dark)\b/, 1]
    assert_includes %w[light dark], hub_mode
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-#{hub_mode}'] .quiz-hud[data-hud-theme='celestial-#{hub_mode}']"
    assert_select ".home-menu-kicker", text: I18n.t("hub_menu.campus")
    assert_select ".home-menu-kicker", text: I18n.t("hub_menu.space")
    assert_select ".home-menu-kicker", text: I18n.t("hub_menu.settings")
    assert_select ".hub-menu-profile .home-menu-row-caret", count: 0
    assert_select ".chrome-drawer a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter"), text: /#{Regexp.escape(I18n.t("hub_menu.invite_friend"))}/
    assert_select ".chrome-drawer a.home-menu-row[href=?]", street_leaderboard_path, text: I18n.t("hub_menu.leaderboard")
    assert_select ".chrome-drawer a.home-menu-row[href=?]", scripture_library_path, text: /#{Regexp.escape(I18n.t("scripture_library.title"))}/
    assert_select ".chrome-drawer a.home-menu-row[href=?]", search_path, text: /#{Regexp.escape(I18n.t("hub_menu.my_ward"))}/
    assert_select ".hub-menu-legal a[href=?]", about_path, text: I18n.t("hub_menu.about_us")
    assert_select ".hub-menu-legal a[href=?]", legal_path, text: I18n.t("hub_menu.legal")
    assert_select ".hub-menu-legal a[href=?]", privacy_path, text: I18n.t("hub_menu.privacy")
    assert_select ".chrome-drawer .place-input", count: 0
    assert_select ".chrome-drawer .code-input", count: 0
    assert_select "details.home-code", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".hub-hero"
    assert_select ".chrome-drawer .mute[data-controller='menu-sound']"
    assert_select ".chrome-drawer .mute .word", text: I18n.t("chrome.sound_on")
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-opt .picto-flag-es"

    start_street_jugar!
    get jugar_path
    assert_select "#street_quiz.play-reel.is-quiz.is-street.is-overlay"
    assert_select ".chrome-drawer .home-menu-nav-hub"
    assert_select "a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter"), text: /#{Regexp.escape(I18n.t("hub_menu.invite_friend"))}/
    assert_select "a.home-menu-row[href=?]", scripture_library_path, text: /#{Regexp.escape(I18n.t("scripture_library.title"))}/
    assert_select ".play-sheet-grip", count: 0
    assert_select ".quiz-hud"
    assert_select ".quiz-hud[data-hud-theme^='celestial-']"
    assert_select ".quiz-hud-streak"
    assert_select ".quiz-hud-streak img.quiz-hud-streak-icon", count: 1
    assert_select ".quiz-hud-streak .quiz-hud-streak-multiplier", text: "×"
    assert_select ".quiz-hud-score .picto-crown"
    assert_select ".street-quiz-apex"
    assert_select ".quiz-sheet"
    assert_select ".street-shot-rival", count: 0
    assert_select ".quiz-hud-rail"
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

  test "every street quiz still has a generated public jpeg while its master stays private" do
    QuizDefinition.catalog.all_questions.each do |question|
      source = "media/#{question.presentation['image']}"
      assert_not Rails.public_path.join(source).exist?, "master leaked into public: #{source}"
      get generated_media_src(source)
      assert_response :success, "missing generated variant for #{source}"
      assert_match %r{image/jpeg}, response.media_type
    end
  end

  test "design tokens and motion live in the stylesheet" do
    css = frontend_css
    assert_includes css, ".sfx-gate"
    assert_includes css, ".mute > * { grid-area: 1 / 1; }"
    assert_includes css, ".chrome-tools"
    assert_includes css, ".scripture-veil[hidden]"
    assert_includes css, "--paper:"
    assert_includes css, "body.is-celestial-dark"
    assert_includes css, '[data-hud-theme="celestial-light"]'
    assert_includes css, '[data-hud-theme="celestial-dark"]'
    assert_equal %w[celestial-dark celestial-light], css.scan(/\[data-hud-theme="([^"]+)"\]/).flatten.uniq.sort
    assert_includes css, "--text-on-glass: var(--text-primary)"
    assert_includes css, ".street-live-dot"
    assert_includes css, "--space-4:"
    assert_includes css, "--dur-press:"
    assert_includes css, "@keyframes ripple"
    assert_includes css, "@keyframes arrive"
    assert_includes css, ".toast-slot"
    assert_includes css, "@keyframes banner-bloom"
    assert_includes css, "@keyframes banner-light-pass"
    assert_includes css, "banner-bloom 7.2s"
    refute_match(/@keyframes banner-bloom\s*\{[^}]*translateY/m, css)
    assert_includes css, "overflow-anchor: none"
    assert_includes css, "--radius-hud:"
    assert_includes css, "backdrop-filter: blur(36px) saturate(1.18) brightness(.98)"
    assert_includes css, "top: calc(max(env(safe-area-inset-top), var(--space-3)) + 6rem)"
    assert_includes css, "@view-transition"
    assert_includes css, "prefers-reduced-motion"
    assert_includes css, ".ficha-search"
    assert_includes css, ".rama-search-sheet .ward-pick-row"
    assert_includes css, ".choice-mark"
    assert_includes css, ".quiz-meta"
    assert_includes css, ".play-reel.is-street.is-quiz .quiz-bar .word"
    refute_includes css, ".play-reel.is-street .quiz-bar.is-right {\n  background: var(--ink);"
    refute_includes css, ".play-reel.is-street .quiz-board.is-right { animation: goldflash"
    refute_includes css, ".choice-token"
    refute_includes css, ".order-chip"
    assert_includes css, ".picto"
    assert_includes css, ".play-reel"
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
    assert_includes css, ".street-world.is-game-hub .street-hub-feed"
    assert_includes css, ".hub-streaming-feed--editorial"
    assert_includes css, "--hub-editorial-hero-scrim:"
    assert_match(/:root,\s*body \{/, css)
    refute_includes css, "is-profile-gate"
    assert_includes css, ".rama-nights"
    assert_includes css, ".home-paper"
    assert_includes css, ".play-reel.is-street"
    assert_includes css, "color-mix(in srgb, var(--temple-marble, var(--paper)) 94%, white)"
    refute_includes css, "--hub-progress-complete:"
    refute_includes css, ".hub-progress-node.is-focus .hub-progress-mark::before"
    motion = Rails.root.join("app/javascript/controllers/motion_controller.js").read
    assert_includes motion, 'target === "street_quiz"'
    assert_includes motion, "wrapStreet"
    refute_includes css, "view-transition-name: street-sheet"
    refute_includes css, "view-transition-name: street-dock"
    assert_includes css, "view-transition-name: street-question-card"
    assert_includes css, "::view-transition-group(street-question-card)"
    assert_includes css, "mix-blend-mode: normal"
    assert_includes css, "view-transition-name: street-score"
    assert_includes css, "view-transition-name: street-still"
    assert_includes css, "view-transition-name: street-hud"
    show = Rails.root.join("app/views/street_plays/show.html.erb").read
    refute_includes show, "view-transition-name: street-quiz"
    quiz_js = Rails.root.join("app/javascript/controllers/quiz_controller.js").read
    refute_includes quiz_js, "overlaySession"
    refute_includes quiz_js, "is-turning"
    assert_includes quiz_js, "is-committing"
    assert_includes quiz_js, "is-advancing"
    assert_includes css, "#street_quiz.is-overlay.is-committing"
    assert_includes css, "#street_quiz.is-overlay.is-advancing"
    assert_includes css, "street-action-from-left"
    assert_includes css, "street-action-from-right"
    assert_includes css, "clip-path: inset(0 100% 0 0)"
    assert_includes css, "clip-path: inset(0 0 0 100%)"
    assert_includes css, "quiz-streak-grow"
    refute_includes css, "quiz-streak-praise"
    refute_includes css, "quiz-legend-praise"
    assert_includes css, ".play-reel.is-street .street-score"
    assert_includes css, ".play-reel.is-street.is-quiz .play-sheet-body"
    assert_includes css, "padding: calc(var(--space-5) + var(--space-1)) var(--space-5)"
    assert_includes css, ".street-world"
    assert_includes css, ".hub-now-card"
    assert_includes css, "street-sheet-rise"
    assert_includes css, ".hall-sheet"
    assert_includes css, ".charter-journey-hero"
    assert_includes css, ".play-timer"
    assert_includes css, ".timer-halo"
    refute_match(/#night_(?:play|watch)/, css)
    refute_match(/#street_quiz\.is-timer-pulse[^}]*animation:/m, css)
    refute_includes css, "@keyframes timer-halo-beat"
    assert_includes css, ".timer-halo { animation: none !important; }"
    refute_includes css, "timer-halo-beat 0.26s"
    refute_includes css, "timer-halo-beat-hot 0.14s"
    refute_includes css, "timer-halo-beat 0.82s"
    refute_includes css, "0% { opacity: 0.38; }"
    refute_includes css, "animation-duration: 0.68s;"
    street_css = Rails.root.join("app/assets/stylesheets/surfaces/street_play.css").read
    refute_match(/animation:[^;]*(?:streak-flicker|quiz-flame-sparks|quiz-next-breathe|cta-breathe)[^;]*infinite/, street_css)
    refute_includes street_css, ".street-hit-flame"
    refute_includes street_css, "--flame-step"
    assert_includes street_css, ".quiz-hud-streak-icon"
    assert_includes street_css, ".street-hit-video"
    assert_includes street_css, ".street-hit-ledger"
    refute_includes street_css, ".street-hit-fire-emblem"
    refute_includes street_css, "@keyframes street-hit-flame-ignite"
    refute_includes street_css, "@keyframes street-hit-flame-snuff"
    assert_match(/prefers-reduced-motion: reduce[\s\S]*\.street-hit-video \{ display: none; \}/m, street_css)
    assert_includes street_css, "animation-name: street-loading-wave"
    assert_match(/@keyframes street-loading-wave[^}]*transform:[^}]*}[^{]*to \{ transform:/m, street_css)
    assert_match(/#street_quiz\.is-overlay \.play-timer\.is-low \.play-timer-bar[^}]*animation: none/m, street_css)
    refute_includes street_css, ".choice-btn:nth-child(1) { animation: quiz-choice-in"
    refute_includes street_css, "view-transition-name: street-praise"
    assert_includes street_css, ".is-result-sequence.is-actions-ready"
    assert_includes css, ".street-praise"
    assert_includes css, ".street-praise.is-streak"
    refute_includes css, ".quiz-streak-shout"
    assert_includes css, "container-name: street-shot"
    assert_includes css, "clamp(1.5rem, 9cqi, 2.55rem)"
    refute_includes css, "clamp(3.9rem, 20vw, 6.1rem)"
    refute_includes css, "scale(1.28)"
    assert_includes css, "body[class*=\"is-fx-\"]::after { display: none; }"
    refute_includes css, ".story-close"
    refute_includes css, ".story-audience"
    refute_includes css, ".story-night"
    refute_includes css, ".night-quiz-head"
    assert_includes css, "--story-type:"
    assert_includes css, "--story-type-soft:"
    assert_includes css, "--story-shadow:"
    assert_includes css, "--scrim-top:"
    assert_includes css, "--scrim-bottom:"
    assert_includes css, "--scrim-board:"
    assert_includes css, "rgba(28, 25, 21, 0.9)"
    assert_includes css, "rgba(28, 25, 21, 0.42)"
    refute_includes css, ".watch-caption"
    refute_includes css, ".stage-caption"
    refute_includes css, "body.is-watch"
    refute_includes css, "linear-gradient(180deg, var(--paper) 0%, transparent 28%)"
    assert_includes css, "--sky:"
    assert_includes css, "--surface-glass-soft"
    assert_includes css, "--surface-glass-medium"
    assert_includes css, "--surface-glass-strong"
    assert_includes css, "#street_quiz.is-overlay"
    assert_includes css, "body.is-street-play #street_quiz.is-overlay .quiz-bar.is-correct"
    assert_includes css, "body.is-street-play #street_quiz.is-overlay .quiz-bar.is-correct .quiz-fill"
    assert_includes css, "body.is-street-play #street_quiz.is-overlay .quiz-flag.is-yes .picto path"
    refute_includes css, "#3d9a5c"
    refute_includes css, "#6fde95"
  end

  test "corporate menu links stay quiet centered and touch accessible" do
    css = frontend_css

    assert_match(/\.hub-menu-legal \{[^}]*justify-content: center;[^}]*text-align: center;/m, css)
    assert_match(/\.hub-menu-legal a \{[^}]*min-height: 2\.75rem;[^}]*font-size: 0\.68rem;/m, css)
    assert_includes css, '.home-menu[data-hud-theme="celestial-dark"] .hub-menu-legal a'
  end

  test "drawer close control keeps a stable accessible silhouette" do
    css = frontend_css

    assert_match(/\.chrome-drawer \.is-drawer-close \{[^}]*width: 2\.75rem;[^}]*height: 2\.75rem;[^}]*border-radius: 0\.7rem;/m, css)
    assert_includes css, ".is-drawer-close .ripple { display: none; }"
    assert_includes css, ".chrome-drawer .quiet-link:not(.is-drawer-close)"
    assert_includes css, '.home-menu[data-hud-theme="celestial-dark"] .is-drawer-close'
  end

  test "shared HUD has no page-specific legacy skins" do
    css = frontend_css
    forbidden = css.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]+)\{([^{}]*)\}/m).filter_map do |selector, declarations|
      selector = selector.strip
      next unless selector.include?("body.") && selector.include?(".quiz-hud")
      next if selector.include?("is-game-hub-page")
      next if selector.include?("#street_quiz")
      next unless declarations.match?(/--(?:quiz|surface|text|border|gold|button|shadow)|(?:^|;)\s*(?:color|background|border-color|box-shadow|backdrop-filter)\s*:/m)

      selector
    end

    assert_empty forbidden, "HUD palette must come only from data-hud-theme, not page selectors: #{forbidden.join(', ')}"
  end

  test "canonical live screen is the automatic watch board" do
    get night_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-night-watch.is-kid"
    assert_select ".noche-live"
    assert_select ".noche-watch-grid"
    assert_select ".noche-watch-ranking"
    assert_select ".noche-watch-progress"
    assert_select ".noche-watch-events"
    assert_select ".noche-live-art picture"
  end

  test "name screen is a frictionless night entry without Story costume" do
    get night_name_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-night-entry.is-celestial-dark"
    assert_select "h1", text: /Entra a la noche/
    assert_select "input[name=name]", count: 1
    assert_select "input[name*='code']", count: 0
    assert_select "a.quiet-link", text: /Soy el presentador/, count: 0
    assert_select "#night_join.night-entry"
    assert_select ".night-entry-panel"
    assert_select ".play-reel", count: 0
    assert_select ".play-shot", count: 0
    assert_select ".play-sheet-grip", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".story-close", count: 0
    assert_select ".picto-btn", count: 0
    assert_select "#night_join"
  end

end
