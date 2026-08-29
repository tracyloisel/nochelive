require "application_system_test_case"

class ReelGrammarVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/reel-shots")

  test "hub join pick lobby rank-up ceremony and watch" do
    set_system_viewport(390, 844)

    visit root_path
    assert_selector "#street_world.street-world"
    assert_no_selector "#street_quiz"
    assert_no_selector ".play-reel.is-home"
    assert_selector ".home-menu"
    assert_no_selector ".place-input"
    assert_no_selector ".story-ticks"
    shot("01-home")

    visit night_name_path(game_sessions(:david).code)
    assert_selector "body.is-night-entry.is-celestial-dark"
    assert_selector "#night_join.night-entry"
    assert_selector ".night-entry-panel"
    assert_no_selector ".play-reel.is-join"
    assert_text I18n.t("join.first_title")
    assert_no_selector ".story-close"
    assert_no_selector ".story-ticks"
    assert_no_selector ".picto-btn"
    shot("02-join")

    fill_in I18n.t("join.name_label"), with: "Pili"
    click_button I18n.t("join.enter_play")
    assert_no_text "Guardar ficha"
    sleep 0.4
    assert_selector ".play-reel.is-night-live"
    assert_selector ".play-shot .challenge-story"
    assert_no_selector ".picto-btn"
    shot("03-pick-team")

    visit night_name_path(game_sessions(:elias).code)
    fill_in I18n.t("join.name_label"), with: "Marta"
    click_button I18n.t("join.enter_play")
    assert_text "Esperad"
    assert_selector ".play-reel.is-lobby"
    assert_selector ".night-quiz-head"
    assert_no_selector ".story-ticks"
    assert_no_selector ".wait-dots"
    assert_no_selector ".street-quiz-lockup-tag"
    assert_selector ".play-shot .challenge-story"
    shot("04-lobby")

    teams(:leones).update!(pending_rank_up: "Explorador", next_correct_doubled: true)
    visit night_name_path(game_sessions(:david).code)
    fill_in I18n.t("join.name_label"), with: "Rita"
    click_button I18n.t("join.enter_play")
    assert_text "Explorador"
    assert_text "Sois Rey"
    assert_button "Seguir la noche"
    assert_selector ".play-reel.is-rank"
    assert_selector ".play-shot .challenge-story"
    assert_no_selector ".picto-btn"
    shot("05-rank-up")

    visit night_name_path(game_sessions(:cerrada).code)
    fill_in I18n.t("join.name_label"), with: "Nico"
    click_button I18n.t("join.enter_play")
    assert_text "¡Campeones gana la noche!"
    assert_selector ".play-reel.is-finale.is-ceremony-immersive"
    assert_selector ".play-sheet[data-sheet-snap=mid] .ceremony-temple"
    assert_selector ".ceremony-arch-crown"
    assert_selector ".play-shot .challenge-story"
    shot("06-ceremony")

    set_system_viewport(1920, 1080)
    visit night_watch_path(game_sessions(:david).code)
    assert_selector ".watch.is-board"
    assert_selector ".watch-shot .challenge-story"
    assert_no_selector ".cheer-dock"
    shot("07-watch")

    visit night_watch_path(game_sessions(:cerrada).code)
    assert_text "¡Campeones gana la noche!"
    assert_selector "#night_watch.is-ceremony-immersive"
    assert_selector ".watch-caption .ceremony-temple"
    assert_selector ".watch-shot .challenge-story"
    assert_no_selector ".cheer-dock"
    caption_share = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(".watch-caption");
        if (!el) return 1;
        return el.getBoundingClientRect().height / window.innerHeight;
      })()
    JS
    assert_operator caption_share, :>=, 0.9
    assert_operator caption_share, :<=, 1.02
    shot("08-watch-ceremony")

    set_system_viewport(390, 844)
    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    visit presenter_console_path(game_sessions(:david).code)
    assert_selector ".stage-shot .challenge-story"
    shot("09-presenter")

    visit presenter_gate_path(game_sessions(:cerrada).code, token: "ended-secret")
    visit presenter_console_path(game_sessions(:cerrada).code)
    assert_selector ".console.is-ceremony-immersive"
    assert_selector ".desk-sheet .ceremony-temple"
    shot("10-presenter-ceremony")
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "reel-shot #{path}"
  end
end
