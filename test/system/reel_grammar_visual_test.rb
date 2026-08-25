require "application_system_test_case"

class ReelGrammarVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/reel-shots")

  test "home join pick lobby rank-up ceremony and watch are reels" do
    page.current_window.resize_to(390, 844)

    visit root_path
    assert_selector ".play-reel.is-home"
    assert_selector ".play-shot .challenge-story"
    assert_selector ".play-sheet"
    assert_button "Entrar"
    shot("01-home")

    visit night_name_path(game_sessions(:david).code)
    assert_selector ".play-reel.is-join"
    assert_selector ".play-shot .challenge-story"
    assert_selector ".play-sheet[data-sheet-snap=mid]"
    assert_text "¿Cómo te llaman?"
    assert_still_peeks
    shot("02-join")

    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    assert_text "Elige tu equipo"
    assert_no_text "Guardar ficha"
    sleep 0.4
    assert_selector ".play-reel.is-pick"
    assert_selector ".play-shot .challenge-story"
    assert_selector ".play-chrome > .team-bar", count: 0
    shot("03-pick-team")

    visit night_name_path(game_sessions(:elias).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Marta"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Leones"
    assert_text "Esperad"
    assert_selector ".play-reel.is-lobby"
    assert_selector ".play-shot .challenge-story"
    shot("04-lobby")

    teams(:leones).update!(pending_rank_up: "Explorador", next_correct_doubled: true)
    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Rita"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Leones de Judá"
    assert_text "Explorador"
    assert_text "Sois Rey"
    assert_button "Seguir la noche"
    assert_selector ".play-reel.is-rank"
    assert_selector ".play-shot .challenge-story"
    shot("05-rank-up")

    visit night_name_path(game_sessions(:cerrada).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Nico"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Campeones"
    assert_text "¡TODOS DE PIE!"
    assert_selector ".play-reel.is-finale"
    assert_selector ".play-sheet[data-sheet-snap=mid] .ceremony"
    assert_selector ".play-shot .challenge-story"
    assert_still_peeks
    shot("06-ceremony")

    page.current_window.resize_to(1920, 1080)
    visit night_watch_path(game_sessions(:david).code)
    assert_selector ".watch.is-board"
    assert_selector ".watch-shot .challenge-story"
    assert_no_selector ".cheer-dock"
    shot("07-watch")

    visit night_watch_path(game_sessions(:cerrada).code)
    assert_text "¡TODOS DE PIE!"
    assert_selector ".watch-shot .challenge-story"
    assert_selector ".watch-caption .ceremony"
    assert_no_selector ".cheer-dock"
    caption_share = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(".watch-caption");
        if (!el) return 1;
        return el.getBoundingClientRect().height / window.innerHeight;
      })()
    JS
    assert_operator caption_share, :<=, 0.55
    shot("08-watch-ceremony")

    page.current_window.resize_to(390, 844)
    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    visit presenter_console_path(game_sessions(:david).code)
    assert_selector ".stage-shot .challenge-story"
    shot("09-presenter")

    visit presenter_gate_path(game_sessions(:cerrada).code, token: "ended-secret")
    visit presenter_console_path(game_sessions(:cerrada).code)
    assert_selector ".stage-shot .challenge-story"
    assert_selector ".desk-sheet .ceremony"
    shot("10-presenter-ceremony")
  end

  def assert_still_peeks
    peek = page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector(".play-sheet");
        if (!sheet) return 0;
        return sheet.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
    assert_operator peek, :>=, 0.42
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "reel-shot #{path}"
  end
end
