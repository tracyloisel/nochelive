require "application_system_test_case"

class StreetQuizVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots")

  test "street quiz sheet type miss ticks and swipe" do
    page.current_window.resize_to(390, 844)
    visit root_path
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
    assert_selector "#street_quiz[data-controller~=story]"
    assert_no_selector ".story-ticks"
    assert_no_selector ".story-close"
    assert_selector ".play-sheet[data-sheet-snap=mid]"
    assert_selector ".quiz-pack"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".btn.btn-gold"
    peek = sheet_top
    assert_operator peek, :>=, 0.42
    pair("01-ask")

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != find("#street_quiz")["data-quiz-correct-value"] }
    wrong.click
    assert_selector ".quiz-board.is-wrong"
    assert_selector ".quiz-bar.is-correct.is-right"
    assert_selector ".quiz-bar.is-wrong.is-miss"
    assert_selector ".quiz-flag"
    assert_selector "a.quiet-link .quiz-cite"
    assert_selector ".play-sheet[data-sheet-snap=open]"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".street-score.is-tick"
    pair("02-miss")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    assert_selector ".play-sheet[data-sheet-snap=mid]"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".btn.btn-gold"
    pair("02b-next-ask")
    first(".choice-btn").click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".play-sheet[data-sheet-snap=open]"
    assert_selector ".street-score"
    pair("03-right")

    swipe("#street_quiz .play-shot", dx: 160, dy: 0)
    assert_selector ".quiz-progress", text: /1 \/ 10/
    assert_selector ".quiz-board.is-settled"
    pair("04-swipe-back")

    swipe("#street_quiz .play-shot", dx: -160, dy: 0)
    assert_selector ".quiz-progress", text: /2 \/ 10/
    pair("05-swipe-next")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    first(".choice-btn").click
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz[data-stage-timer-end-value]"
    assert_selector "#street_quiz[data-stage-timer-duration-value]"
    duration = find("#street_quiz")["data-stage-timer-duration-value"].to_i
    assert_operator duration, :>, 0
    pair("06-timed")
  end

  def pair(name)
    page.current_window.resize_to(390, 844)
    shot("#{name}-phone")
    page.current_window.resize_to(1280, 800)
    shot("#{name}-desktop")
    page.current_window.resize_to(390, 844)
  end

  def sheet_top
    page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector("#street_quiz .play-sheet");
        if (!sheet) return 0;
        return sheet.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
  end

  def swipe(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      var el = document.querySelector(arguments[0]);
      var r = el.getBoundingClientRect();
      var x = r.left + r.width * 0.5;
      var y = r.top + r.height * 0.4;
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
    warn "street-shot #{path}"
  end
end
