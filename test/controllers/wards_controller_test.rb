require "test_helper"

class WardsControllerTest < ActionDispatch::IntegrationTest
  test "create a rama then a night" do
    get new_ward_path
    assert_response :success
    assert_select "input[placeholder='Rama Benidorm']"

    assert_difference -> { Ward.count }, 1 do
      post wards_path, params: {
        name: "Rama Valencia",
        emblem: "leon",
        chapel_address: "Calle Falsa 1",
        city: "Valencia",
        country_code: "ES"
      }
    end
    ward = Ward.order(:id).last
    assert_equal "leon", ward.emblem
    assert_equal "Valencia", ward.city
    assert_not ward.listed?
    assert_redirected_to ward_profile_path(ward.code)
    follow_redirect!
    assert_response :success

    assert_difference -> { GameSession.count }, 1 do
      post game_sessions_path
    end
  end
end
