require "test_helper"

class StreetPlaysControllerTest < ActionDispatch::IntegrationTest
  test "jugar requires an open run" do
    get jugar_path
    assert_redirected_to root_path
  end

  test "jugar shows reel with level rail" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz.play-reel.is-street"
    assert_select ".street-quiz-head"
    assert_select ".street-quiz-lockup-name", text: "Noche Live"
    assert_select ".street-quiz-apex"
    assert_select ".street-score"
    assert_select ".street-shot-rival"
    assert_select ".street-level-rail"
    assert_select ".street-back-map", count: 0
    assert_select ".street-map", count: 0
    assert_select "a.home-menu-row[href=?]", root_path, text: I18n.t("street.ceremony_back_map")
  end
end
