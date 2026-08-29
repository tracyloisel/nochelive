require "application_system_test_case"

class NightTempleVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/night-shots/temple-themed")

  test "live play reel shows temple marble sheet star chrome and gold arch" do
    visit night_name_path(game_sessions(:david).code)
    assert_selector "body.is-night-entry.is-celestial-dark"
    assert_selector "#night_join .night-entry-panel"
    assert_no_selector ".play-reel"
    assert_no_selector ".picto-btn"
    shot("join-sheet")
    fill_in I18n.t("join.name_label"), with: "Pili"
    click_button I18n.t("join.enter_play")
    assert_button "Buzz"
    assert_selector ".play-sheet"
    assert_selector ".story-ticks"
    assert_selector ".night-quiz-head"
    assert_selector ".night-quiz-head .story-close"
    assert_selector ".play-shot-seat"
    assert_button "Buzz"
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
    visit night_name_path(game_sessions(:david).code, location: "remote")
    fill_in I18n.t("join.name_label"), with: "Casa"
    click_button I18n.t("join.enter_play")
    assert_selector ".play-reel.is-quiz.is-night-live"
    assert_selector ".night-quiz-head"
    assert_selector ".night-quiz-head .story-close"
    assert_selector ".play-shot-seat"
    assert_selector ".choice-btn", minimum: 2
    assert_text "Riquezas"
    assert_text "Sabiduría"
    assert_no_button "Buzz"
    assert_no_selector ".play-sheet-grip"
    assert_text "¿Qué pidió?"
    sleep 0.4
    shot("play-quiz-casa")
    set_system_viewport(1280, 800)
    sleep 0.3
    shot("play-quiz-casa-desktop")
    set_system_viewport(390, 844)
  end

  test "choice quiz shows temple choice buttons and gold arch" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)

    visit night_name_path(game_sessions(:david).code)
    fill_in I18n.t("join.name_label"), with: "Quiz"
    click_button I18n.t("join.enter_play")
    assert_selector ".play-reel.is-quiz"
    assert_selector ".night-quiz-head"
    assert_selector ".choice-btn", minimum: 2
    assert_text "Elías fue un rey de Israel."
    assert_play_shot_arch
    assert_selector ".story-ticks"
    sleep 0.45
    shot("play-quiz-ask")
    set_system_viewport(1280, 800)
    sleep 0.3
    shot("play-quiz-ask-desktop")
    set_system_viewport(390, 844)
  end

  test "presenter stage shows marble desk chrome" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    Buzz.create!(round_run: round, team: teams(:leones), player: players(:lucia), position: 1, latency_ms: 400)

    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    assert_selector ".console.is-stage"
    assert_selector ".code-chip"
    assert_stage_shot_arch
    peek = page.evaluate_script(<<~JS)
      (function() {
        var tabs = document.querySelector(".desk-tabs");
        var row = document.querySelector(".buzz-board li");
        if (!tabs) return [0, 0];
        var t = tabs.getBoundingClientRect();
        var tabsOk = t.top >= 0 && t.bottom <= (window.innerHeight + 8) && t.height > 0 ? 1 : 0;
        if (!row) return [tabsOk, 0];
        var r = row.getBoundingClientRect();
        var rowOk = r.top >= 0 && r.top < window.innerHeight && r.height > 0 ? 1 : 0;
        return [tabsOk, rowOk];
      })()
    JS
    assert_equal 1, peek[0], "Lista/Fichas tabs should sit in the desk peek"
    assert_equal 1, peek[1], "first buzz row should peek on the marble desk"
    shot("presenter-stage")
    set_system_viewport(1280, 800)
    sleep 0.3
    shot("presenter-stage-desktop")
    set_system_viewport(390, 844)
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
    assert_selector ".watch-corner", count: 4
    assert_watch_shot_arch
    mute_display = page.evaluate_script("getComputedStyle(document.querySelector('.chrome-tools .mute')).display")
    assert_equal "none", mute_display
    sleep 0.5
    shot("watch-board")
    set_system_viewport(1280, 800)
    sleep 0.3
    shot("watch-board-desktop")
    set_system_viewport(1024, 768)
    sleep 0.3
    shot("watch-board-cinema")
    set_system_viewport(844, 390)
    sleep 0.3
    board_share = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector(".watch-shot");
        var board = document.querySelector(".watch-board");
        var caption = document.querySelector(".watch-caption");
        if (!shot || !board) return [1, 1, 0, 0];
        var s = shot.getBoundingClientRect();
        var b = board.getBoundingClientRect();
        var c = caption ? caption.getBoundingClientRect() : { height: 0, bottom: 0, top: 0 };
        if (s.height <= 0) return [1, 1, 0, 0];
        return [
          b.height / s.height,
          c.height / s.height,
          c.bottom <= b.top + 2 ? 1 : 0,
          c.top > s.top + s.height * 0.5 ? 1 : 0
        ];
      })()
    JS
    assert board_share[0] < 0.42, "landscape watch board should stay a lower-third, got #{board_share[0]}"
    assert board_share[1] < 0.28, "landscape watch caption should not cover the light-beam, got #{board_share[1]}"
    assert_equal 1, board_share[2], "landscape watch caption should sit on the still, above the marble strip"
    assert_equal 1, board_share[3], "landscape watch caption should sit in the lower half, off the light-beam"
    shot("watch-board-landscape")
    set_system_viewport(390, 844)
  end

  test "finished night play shows temple ceremony scrim" do
    set_system_viewport(390, 844)
    visit night_name_path(game_sessions(:cerrada).code)
    fill_in I18n.t("join.name_label"), with: "Finale"
    click_button I18n.t("join.enter_play")
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
    set_system_viewport(390, 844)
    visit night_name_path(game_sessions(:elias).code)
    fill_in I18n.t("join.name_label"), with: "Marta"
    click_button I18n.t("join.enter_play")
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

  test "search paper surface sits on the marble hall" do
    set_system_viewport(390, 844)
    visit search_path
    assert_selector "body.is-paper-hall"
    assert_selector "h1", text: I18n.t("home.menu_search")
    assert_selector ".home-search-lede"
    assert_selector "#ward_q"
    assert_no_text I18n.t("home.search_wait")
    assert_no_selector ".btn-gold"
    assert_no_selector ".ward-hit"
    assert_selector ".ward-picker-locate", text: I18n.t("street.gate_locate")
    sleep 0.35
    shot("buscar-phone")

    set_system_viewport(768, 1024)
    assert_no_selector ".ward-hit"
    shot("buscar-tablet")

    set_system_viewport(390, 844)
    visit search_path(q: "Benidorm")
    assert_selector ".ward-pick-form.is-featured .ward-pick-star", visible: :all
    assert_no_selector ".ward-pick-form.is-featured .ward-pick-star", visible: true
    assert_no_selector ".ward-hit.is-featured .ward-pick-star"
    assert_selector ".ward-pick-form.is-featured .ward-hit.is-featured", visible: true
    sleep 0.35
    shot("buscar-benidorm-star")

    set_system_viewport(1440, 900)
    sleep 0.3
    shot("buscar-desktop")
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "night-temple-shot #{path}"
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
        return before.content !== "none" && parseFloat(before.borderWidth) >= 2;
      })()
    JS
    assert has_arch, "watch shot should have gold arch frame"
  end
end
