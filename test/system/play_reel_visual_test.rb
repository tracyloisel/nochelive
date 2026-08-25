require "application_system_test_case"

class PlayReelVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/play-shots")

  test "phone play reel keeps question and buzz on the first screen" do
    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    assert_text "Elige tu equipo"
    click_button "Casa de David"
    assert_no_text "Elige tu equipo"
    assert_button "Buzz"
    assert_selector ".play-timer"
    assert_selector ".play-sheet"
    assert_selector ".story-close"
    assert_selector ".story-ticks"
    assert_selector ".story-night", text: /Reyes y Profetas/
    assert_no_selector ".story-audience"
    assert_selector ".story-score"
    assert_selector ".challenge-story"
    assert_no_selector ".play-round > .art"
    assert_no_selector "[data-controller=slideshow]"
    sleep 0.5
    assert_in_viewport ".prompt"
    assert_in_viewport ".buzz"
    mute_top = page.evaluate_script("document.querySelector('.mute').getBoundingClientRect().top")
    lang_top = page.evaluate_script("document.querySelector('.lang-switch').getBoundingClientRect().top")
    mute_bottom = page.evaluate_script("document.querySelector('.mute').getBoundingClientRect().bottom")
    sheet_top = page.evaluate_script("document.querySelector('.play-sheet').getBoundingClientRect().top")
    chrome_bottom = page.evaluate_script("document.querySelector('.play-chrome').getBoundingClientRect().bottom")
    ticks_top = page.evaluate_script("document.querySelector('.story-ticks').getBoundingClientRect().top")
    assert mute_top < 80, "mute should sit at the top of the play reel"
    assert lang_top >= mute_bottom - 1, "language flags should sit under mute"
    assert ticks_top < 36, "round ticks should sit at the very top, like a story"
    tick_h = page.evaluate_script("document.querySelector('.story-tick').getBoundingClientRect().height")
    assert tick_h >= 40, "round ticks should be easy to tap"
    title_top = page.evaluate_script("document.querySelector('.story-night').getBoundingClientRect().top")
    score_top = page.evaluate_script("document.querySelector('.story-score').getBoundingClientRect().top")
    assert (title_top - score_top).abs < 24, "score pill should sit on the night title row"
    gap = page.evaluate_script(<<~JS)
      (function() {
        var title = document.querySelector(".story-night").getBoundingClientRect();
        var score = document.querySelector(".story-score").getBoundingClientRect();
        return score.left - title.right;
      })();
    JS
    assert gap >= 0 && gap < 20, "score pill should sit immediately after the night title"
    assert chrome_bottom < 240, "story chrome should stay a thin overlay over the drawing"
    assert sheet_top > 80, "the illustration should peek above the question card"
    shot("01-buzz-open-844")
    page.current_window.resize_to(390, 667)
    assert_in_viewport ".prompt"
    assert_in_viewport ".buzz"
    shot("01b-buzz-open-667")
    page.current_window.resize_to(390, 844)

    click_button "Buzz"
    assert_text "1.º"
    shot("02-buzz-locked")

    result = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(".play-sheet");
        var ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "sheet");
        if (!ctrl) return "no-ctrl";
        if (typeof ctrl.snapTo !== "function") {
          return "methods:" + Object.getOwnPropertyNames(Object.getPrototypeOf(ctrl)).join(",");
        }
        ctrl.snapTo("peek", true);
        return [el.dataset.sheetSnap, el.getAttribute("data-sheet-snap-value"), ctrl.snapValue].join("|");
      })();
    JS
    assert_equal "peek|peek|peek", result
    sleep 0.45
    shot("03-sheet-peek")
  end

  test "choice verdict and bars stay on one story sheet" do
    round_runs(:salomon).update_columns(phase: "completed")
    round_runs(:rey_o_profeta).update_columns(phase: "open", opened_at: Time.current)

    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    assert_text "Elige tu equipo"
    click_button "Casa de David"
    assert_text "Elías fue un rey de Israel."
    assert_in_viewport ".choice-btn"
    click_button "Falso"
    assert_text "¡Correcto!"
    assert_text "Falso. Elías fue profeta."
    assert_selector ".quiz-bar"
    assert_button "Siguiente"
    assert_no_selector ".reveal"
    assert_no_selector ".wait-toy"
    assert_in_viewport ".quiz-next"
    shot("04-choice-verdict")
  end

  test "four quiz choices stay on screen with the drawing" do
    round_runs(:salomon).update_columns(phase: "completed")
    round_runs(:rey_o_profeta).update_columns(phase: "completed")
    round_runs(:david_goliath).update_columns(phase: "completed")
    round_runs(:elias_carmel).update_columns(phase: "open", opened_at: Time.current)

    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Casa de David"
    assert_text "¿Qué bajó sobre el altar de Elías en el Carmelo?"
    assert_selector ".choice-btn", count: 4
    assert_in_viewport ".choice-btn"
    last_bottom = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(".choices form:last-child .choice-btn");
        if (!el) return 9999;
        return el.getBoundingClientRect().bottom;
      })()
    JS
    assert_operator last_bottom, :<=, page.evaluate_script("window.innerHeight") + 12
    peek = page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector(".play-sheet");
        if (!sheet) return 0;
        return sheet.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
    assert_operator peek, :>=, 0.38
    assert_operator peek, :<=, 0.47
    shot("06-quiz-four-asking")

    click_button "Fuego"
    assert_text "¡Correcto!"
    assert_selector ".quiz-bar", count: 4
    assert_button "Siguiente"
    assert_in_viewport ".quiz-bar"
    assert_in_viewport ".quiz-next"
    shot("06-quiz-four-verdict")
  end

  def assert_in_viewport(selector)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        return r.top >= -8 && r.bottom <= (window.innerHeight + 8) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit in the first screen"
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "play-shot #{path}"
  end
end
