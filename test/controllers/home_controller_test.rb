require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home and health" do
    get root_path
    assert_response :success
    get "/up"
    assert_response :success
  end

  test "home lists live nights and hides finished ones" do
    get root_path
    assert_select ".night-menu"
    assert_select "img.night-poster"
    assert_select ".night-hit", text: /DAVID/
    assert_select ".night-hit", text: /ELIAS/
    assert_select ".night-hit", text: /QUIT/, count: 0
    assert_select "h2", text: "Reyes y Profetas"
    assert_select "a.btn.btn-navy", text: /Crear una noche/
    assert_select "button.quiet-link", text: /Soy el presentador/
    assert_select "button.quiet-link", text: /Solo ver/
  end

  test "home remembers finished nights when the rama is signed in" do
    sign_in_ward
    get root_path
    assert_select ".memory-shelf", text: /QUIT/
    assert_select ".memory-shelf", text: /Élder Soto/
    assert_select ".memory-shelf", text: /Hermana Clark/
  end

  test "home shows the program when no night is open" do
    GameSession.live.update_all(status: "finished")
    get root_path
    assert_select ".night-program", text: /Reyes y Profetas/
    assert_select ".night-hit", count: 0
    assert_select ".night-acts"
  end
end
