require "application_system_test_case"

class StoryGesturesTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/story-shots")

  test "play story close returns home and ticks browse rounds" do
    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Casa de David"
    assert_selector ".play-reel[data-controller=story]"
    assert_selector ".story-close"
    assert_selector ".story-night", text: /Reyes y Profetas/
    assert_no_selector ".story-audience"
    assert_selector ".story-score"
    shot("01-play-story")

    find(".story-score").click
    assert_text "Casa de David"
    assert_selector ".score-pop .team-bar", visible: true
    shot("01b-play-score")
    find(".story-score").click
    assert_no_selector ".score-pop .team-bar", visible: true

    page.execute_script(<<~JS)
      var el = document.querySelector(".play-reel");
      window.Stimulus.getControllerForElementAndIdentifier(el, "story").next();
    JS
    assert_text "Pronto"
    shot("02-play-next-round")

    page.execute_script(<<~JS)
      var el = document.querySelector(".play-reel");
      window.Stimulus.getControllerForElementAndIdentifier(el, "story").live();
    JS
    assert_button "Buzz"
    shot("03-play-back-live")

    find("a.story-close").click
    assert_text "Noche Live"
    assert_current_path root_path
    shot("04-play-home")
  end

  test "play swipe down leaves the story" do
    visit night_name_path(game_sessions(:david).code)
    fill_in "¿Cómo te llaman en la rama?", with: "Pili"
    find("label.choice-chip", text: "En la sala").click
    click_button "Solo esta noche"
    click_button "Casa de David"
    assert_selector ".play-reel"

    page.execute_script(<<~JS)
      var el = document.querySelector(".play-sheet");
      window.Stimulus.getControllerForElementAndIdentifier(el, "sheet").snapTo("peek", false);
    JS
    swipe(".play-shot", dx: 0, dy: 220)
    assert_text "Noche Live"
    assert_current_path root_path
  end

  test "console story close and swipe up open the desk" do
    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    assert_selector ".console.is-stage[data-controller=story]"
    assert_selector ".story-close"
    shot("05-console-story")

    page.execute_script(<<~JS)
      var el = document.querySelector(".desk-sheet");
      window.Stimulus.getControllerForElementAndIdentifier(el, "sheet").snapTo("open", true);
    JS
    assert_text "Marcador", wait: 2
    shot("06-console-desk")

    find("a.story-close").click
    assert_text "Noche Live"
    assert_current_path root_path
  end

  def swipe(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      var el = document.querySelector(arguments[0]);
      var r = el.getBoundingClientRect();
      var x = r.left + r.width * 0.5;
      var y = r.top + r.height * 0.25;
      var dx = arguments[1];
      var dy = arguments[2];
      var fire = function(type, cx, cy) {
        el.dispatchEvent(new PointerEvent(type, {
          bubbles: true, cancelable: true, pointerId: 1, pointerType: "touch",
          clientX: cx, clientY: cy
        }));
      };
      fire("pointerdown", x, y);
      fire("pointermove", x + dx * 0.35, y + dy * 0.35);
      fire("pointermove", x + dx, y + dy);
      fire("pointerup", x + dx, y + dy);
    JS
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "story-shot #{path}"
  end
end
