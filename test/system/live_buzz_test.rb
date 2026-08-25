require "application_system_test_case"

class LiveBuzzTest < ApplicationSystemTestCase
  test "two phones slam the same open buzzer and take first and second" do
    code = nil

    using_session(:host) do
      visit ward_gate_path
      fill_in "Código de la rama", with: "BLANK"
      fill_in "Secreto del presentador", with: "rama-blank"
      click_button "Entrar"
      click_button "Abrir la noche"
      assert_selector ".code-display"
      code = find(".code-display").text
      click_link "Abrir consola"
      click_button "Empezar la noche"
      click_button "Abrir"
      assert_button "Cerrar buzzer"
    end

    using_session(:lucia) do
      join_night(code, name: "Lucía", team: "Leones", emblem: "leon")
      assert_button "Buzz"
    end

    using_session(:carlos) do
      join_night(code, name: "Carlos", location: "room", team: "Casa", emblem: "ola")
      assert_button "Buzz"
    end

    using_session(:lucia) { click_button "Buzz" }
    using_session(:carlos) { click_button "Buzz" }

    using_session(:lucia) { assert_text "1.º" }
    using_session(:carlos) { assert_text "2.º" }

    using_session(:watch) do
      visit night_watch_path(code)
      assert_text "buzzó primero"
    end
  end
end
