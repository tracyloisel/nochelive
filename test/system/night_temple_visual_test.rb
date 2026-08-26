require "application_system_test_case"

class NightTempleVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/night-shots/temple-themed")

  test "live play reel shows temple marble sheet star chrome and gold arch" do
    visit night_name_path(game_sessions(:david).code)
    assert_selector "body.is-paper-hall"
    assert_selector "#night_join .hall-sheet"
    assert_no_selector ".play-reel"
    assert_no_selector ".picto-btn"
    shot("join-sheet")
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    assert_text "Elige tu equipo"
    click_button "Casa de David"
    assert_button "Buzz"
    assert_selector ".play-sheet"
    assert_selector ".story-ticks"
    assert_selector ".night-quiz-head"
    assert_play_shot_arch
    has_star = page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector(".play-sheet");
        return sheet && getComputedStyle(sheet, "::before").content !== "none";
      })()
    JS
    assert has_star, "play sheet should have apex star ornament"
    sleep 0.4
    shot("play-buzz-open")
  end

  test "casa remote quiz shows temple QCM without a buzzer" do
    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Casa"
    find("label.choice-chip", text: "En casa").click
    click_button "Solo esta noche"
    assert_selector ".play-reel.is-quiz.is-night-live"
    assert_selector ".night-quiz-head"
    assert_selector ".choice-btn", minimum: 2
    assert_no_button "Buzz"
    assert_no_selector ".play-sheet-grip"
    assert_text "¿Qué pidió?"
    sleep 0.4
    shot("play-quiz-casa")
    page.current_window.resize_to(1280, 800)
    sleep 0.3
    shot("play-quiz-casa-desktop")
    page.current_window.resize_to(390, 844)
  end

  test "choice quiz shows temple choice buttons and gold arch" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)

    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Quiz"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    assert_text "Elige tu equipo"
    click_button "Casa de David"
    assert_selector ".play-reel.is-quiz"
    assert_selector ".night-quiz-head"
    assert_selector ".choice-btn", minimum: 2
    assert_text "Elías fue un rey de Israel."
    assert_play_shot_arch
    assert_selector ".story-ticks"
    sleep 0.45
    shot("play-quiz-ask")
    page.current_window.resize_to(1280, 800)
    sleep 0.3
    shot("play-quiz-ask-desktop")
    page.current_window.resize_to(390, 844)
  end

  test "presenter stage shows marble desk chrome" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)

    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    assert_selector ".console.is-stage"
    assert_selector ".code-chip"
    assert_stage_shot_arch
    shot("presenter-stage")
    page.current_window.resize_to(1280, 800)
    sleep 0.3
    shot("presenter-stage-desktop")
    page.current_window.resize_to(390, 844)
    page.execute_script(<<~JS)
      var el = document.querySelector(".desk-sheet");
      var ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "sheet");
      ctrl.snapTo("open", false);
    JS
    sleep 0.35
    shot("presenter-desk-open")
  end

  test "watch board shows temple cinema chrome" do
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)

    visit night_watch_path(game_sessions(:david).code)
    assert_selector ".watch.is-board"
    assert_watch_shot_arch
    sleep 0.5
    shot("watch-board")
    page.current_window.resize_to(1280, 800)
    sleep 0.3
    shot("watch-board-desktop")
  end

  test "finished night play shows temple ceremony scrim" do
    page.current_window.resize_to(390, 844)
    visit night_name_path(game_sessions(:cerrada).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Finale"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Campeones"
    assert_selector ".play-reel.is-finale.is-ceremony-immersive"
    assert_selector ".ceremony-temple .ceremony-arch-crown"
    page.execute_script(<<~JS)
      var el = document.querySelector(".play-reel.is-finale .play-sheet");
      var ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "sheet");
      ctrl.snapTo("open", false);
    JS
    assert_text "Campeones"
    sleep 0.4
    shot("play-finale-ceremony")
  end

  test "lobby wait uses temple three-band without round ticks" do
    page.current_window.resize_to(390, 844)
    visit night_name_path(game_sessions(:elias).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Marta"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Leones"
    assert_text "Esperad"
    assert_selector ".play-reel.is-lobby.is-night-live"
    assert_selector ".night-quiz-head"
    assert_selector ".night-quiz-head .story-close"
    assert_selector ".lobby-wait"
    assert_selector ".play-shot-seat"
    assert_no_selector ".story-ticks"
    assert_no_selector ".wait-dots"
    assert_no_selector ".street-quiz-lockup-tag"
    assert_play_shot_arch
    sleep 0.35
    shot("play-lobby-wait")
  end

  test "noches paper feed sits on the marble hall" do
    page.current_window.resize_to(390, 844)
    visit nights_path
    assert_selector "body.is-paper-hall"
    assert_selector ".home-paper"
    assert_selector ".street-hub-lockup-star"
    assert_selector "h1", text: "Noche Live"
    assert_selector ".street-hub-kicker", text: /#{Regexp.escape(I18n.t("home.nights"))}/i
    assert_selector ".home-doors a.btn-gold", text: I18n.t("church.invite")
    assert_selector ".night-still .night-poster"
    assert_no_selector ".home-doors a", text: I18n.t("home.who")
    assert_no_selector ".home-doors a", text: I18n.t("home.search_page")
    assert_no_selector ".story-ticks"
    sleep 0.4
    shot("noches-phone")

    page.current_window.resize_to(1280, 844)
    sleep 0.3
    shot("noches-desktop")

    page.current_window.resize_to(390, 844)
    visit search_path
    assert_selector "body.is-paper-hall"
    assert_selector "h1", text: I18n.t("home.menu_search")
    assert_selector ".home-search-lede"
    assert_selector "#ward_q"
    assert_no_selector ".btn-gold"
    sleep 0.35
    shot("buscar-phone")

    visit search_path(q: "Benidorm")
    assert_selector ".ward-pick-form.is-featured .ward-pick-star"
    assert_no_selector ".ward-hit.is-featured .ward-pick-star"
    assert_featured_star_sits_above_card
    sleep 0.35
    shot("buscar-benidorm-star")

    page.current_window.resize_to(1280, 844)
    sleep 0.3
    shot("buscar-desktop")
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "night-temple-shot #{path}"
  end

  def assert_featured_star_sits_above_card
    metrics = page.evaluate_script(<<~JS)
      (function() {
        var form = document.querySelector(".ward-pick-form.is-featured");
        var star = document.querySelector(".ward-pick-form.is-featured .ward-pick-star");
        var glyph = star && star.querySelector(".picto");
        var btn = document.querySelector(".ward-hit.is-featured");
        if (!form || !star || !glyph || !btn) return null;
        var f = form.getBoundingClientRect();
        var s = star.getBoundingClientRect();
        var g = glyph.getBoundingClientRect();
        var b = btn.getBoundingClientRect();
        return {
          glyphTop: Math.round(g.top),
          glyphBottom: Math.round(g.bottom),
          starTop: Math.round(s.top),
          btnTop: Math.round(b.top),
          formTop: Math.round(f.top),
          overflow: getComputedStyle(form).overflow
        };
      })()
    JS
    assert metrics, "featured Benidorm card should render a star"
    assert_operator metrics["starTop"], :>=, metrics["formTop"] - 1
    assert_operator metrics["glyphTop"], :>=, metrics["formTop"] - 1
    assert_operator metrics["glyphBottom"], :<=, metrics["btnTop"] + 4
    assert_equal "visible", metrics["overflow"]
  end

  def assert_play_shot_arch
    has_arch = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector(".play-shot");
        if (!shot) return false;
        var before = getComputedStyle(shot, "::before");
        return before.content !== "none" && parseFloat(before.borderWidth) >= 3;
      })()
    JS
    assert has_arch, "play shot should have outer gold arch frame"
  end

  def assert_stage_shot_arch
    has_arch = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector(".stage-shot");
        if (!shot) return false;
        var before = getComputedStyle(shot, "::before");
        return before.content !== "none" && parseFloat(before.borderWidth) >= 3;
      })()
    JS
    assert has_arch, "presenter stage shot should have gold arch frame"
  end

  def assert_watch_shot_arch
    has_arch = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector(".watch-shot");
        if (!shot) return false;
        var before = getComputedStyle(shot, "::before");
        return before.content !== "none" && parseFloat(before.borderWidth) >= 3;
      })()
    JS
    assert has_arch, "watch shot should have gold arch frame"
  end
end
