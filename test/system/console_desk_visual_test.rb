require "application_system_test_case"

class ConsoleDeskVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/console-shots")

  test "presenter desk tabs keep answers off the scoreboard" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    Answer.create!(round_run: round, team: teams(:leones), player: players(:lucia), body: "false")
    Answer.create!(round_run: round, team: teams(:casa), player: players(:daniel), body: "true")
    Scores::Apply.correct!(round, teams(:leones), broadcast: false)
    Scores::Apply.incorrect!(round, teams(:casa), broadcast: false)

    visit presenter_gate_path(game_sessions(:david).code, token: "presenter-secret")
    assert_selector ".console.is-stage"
    assert_selector ".story-close"
    page.execute_script(<<~JS)
      var el = document.querySelector(".desk-sheet");
      var ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "sheet");
      ctrl.snapTo("open", false);
    JS
    sleep 0.35
    assert_selector ".desk-tabs"
    shot("01-reel")

    assert_css ".desk-tab[data-desk-pane=respuestas][aria-selected=true]"
    assert_text "Falso"
    assert_text "Verdadero"
    assert_selector "input[placeholder='Buscar equipo o respuesta']"
    assert_no_selector ".desk-pane[data-desk-pane=marcador] .desk-team", visible: true
    assert_selector ".desk-mark.is-yes .picto-tick"
    assert_selector ".desk-mark.is-no .picto-cross"
    assert_in_viewport ".desk-tabs"
    assert_in_viewport ".desk-answer"
    shot("02-respuestas")

    find(".desk-tab", text: "Marcador").click
    assert_css ".desk-tab[data-desk-pane=marcador][aria-selected=true]"
    assert_button "+5"
    assert_button "−5"
    assert_text "Historial de puntos"
    assert_no_selector ".desk-answer", visible: true
    shot("03-marcador")

    find(".desk-tab", text: /Respuestas/).click
    find("input[type=search]").set("Casa")
    assert_selector ".desk-answer", text: /Verdadero/, visible: true
    assert_no_selector ".desk-answer", text: /Falso/, visible: true
    shot("04-search")
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
    assert visible, "#{selector} should sit in the first desk screen"
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    warn "console-shot #{path}"
  end
end
