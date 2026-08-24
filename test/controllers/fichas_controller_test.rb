require "test_helper"

class FichasControllerTest < ActionDispatch::IntegrationTest
  test "ward presenter lists fichas and can read the year" do
    sign_in_ward
    get ward_fichas_path
    assert_response :success
    assert_select "h1", "Fichas de la rama"
    assert_select "a", /Carmen/
    get ward_ficha_path(people(:carmen_garcia))
    assert_response :success
    assert_select ".year-shout", "1833"
  end

  test "ward presenter edits and merges fichas" do
    sign_in_ward
    patch ward_ficha_path(people(:pili)), params: {
      given_name: "Pilar",
      family_name: "",
      avatar_key: "tortuga",
      favorite_year: 1991
    }
    assert_redirected_to ward_ficha_path(people(:pili))
    assert_equal 1991, people(:pili).reload.favorite_year

    source = people(:carmen_lopez)
    post ward_ficha_merge_path(people(:carmen_garcia)), params: { source_id: source.id }
    assert_redirected_to ward_ficha_path(people(:carmen_garcia))
    assert_not Person.exists?(source.id)
  end
end
