require "test_helper"

class UiChromeTest < ActionDispatch::IntegrationTest
  test "home page ships the white motion chrome" do
    get root_path
    assert_response :success
    assert_select 'meta[name="view-transition"][content="same-origin"]'
    assert_select 'meta[name="theme-color"][content="#f6f3ec"]'
    assert_select "body[data-controller~=press][data-controller~=motion]"
    assert_select "body.is-kid"
    assert_select ".gate"
    assert_select ".night-menu"
    assert_select "img.night-poster"
    assert_select ".btn.btn-gold", text: /Entrar/
    assert_select ".btn.btn-gold .picto"
    assert_select ".picto-door"
    assert_select ".btn.btn-ghost"
    assert_select ".btn.btn-navy"
  end

  test "design tokens and motion live in the stylesheet" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, "--paper:"
    assert_includes css, "--space-4:"
    assert_includes css, "--dur-press:"
    assert_includes css, "@keyframes ripple"
    assert_includes css, "@keyframes arrive"
    assert_includes css, "@view-transition"
    assert_includes css, "prefers-reduced-motion"
    assert_includes css, "fieldset.place"
    assert_includes css, "p.place"
    assert_includes css, ".picture-card"
    assert_includes css, ".choice-mark"
    assert_includes css, ".choice-token"
    assert_includes css, ".order-chip"
    assert_includes css, ".picto"
    assert_includes css, ".play-reel"
    assert_includes css, ".play-timer"
    assert_includes css, ".story-close"
    assert_includes css, ".story-ticks"
    assert_includes css, ".story-audience"
    assert_includes css, ".story-score"
    assert_includes css, ".is-kid .story-audience.btn"
    assert_includes css, ".story-night"
    assert_includes css, "--sky:"
  end

  test "watch screen is a kid picture board" do
    get night_watch_path(game_sessions(:david).code)
    assert_response :success
    assert_select "body.is-watch.is-kid"
    assert_select ".live"
    assert_select ".live-dot"
    assert_select ".challenge-story[src='/media/stories/salomon_wisdom.jpg']"
  end

  test "name screen uses picture cards a child can tap" do
    get night_name_path(game_sessions(:david).code)
    assert_response :success
    assert_select "h1", text: /llama/
    assert_select ".picture-card", count: 2
    assert_select ".picto-sofa"
    assert_select ".picto-house"
    assert_select "a.btn", text: /Soy el presentador/
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
    assert_select ".desk-tabs"
    assert_select ".desk-board[aria-label=Marcador]"
    assert_select ".desk-team"
    assert_select ".stage-reel .stage-rail"
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, ".stage-dock"
    assert_includes css, ".stage-shot"
    assert_includes css, ".code-chip"
    assert_includes css, ".desk-team"
    assert_includes css, ".desk-tabs"
    assert_includes css, ".desk-mark"
    assert_includes css, "--desk-radius:"
  end
end
