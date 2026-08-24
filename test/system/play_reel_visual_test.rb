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
    assert_no_selector ".play-round > .art"
    sleep 0.5
    assert_in_viewport ".prompt"
    assert_in_viewport ".buzz"

    shot("01-buzz-open-844")
    page.current_window.resize_to(390, 667)
    assert_in_viewport ".prompt"
    assert_in_viewport ".buzz"
    shot("01b-buzz-open-667")
    page.current_window.resize_to(390, 844)

    click_button "Buzz"
    assert_text "1.º"
    shot("02-buzz-locked")
  end

  def assert_in_viewport(selector)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        return r.top >= 0 && r.bottom <= (window.innerHeight + 1) && r.height > 0;
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
