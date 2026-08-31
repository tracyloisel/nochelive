require "test_helper"

class FichasControllerTest < ActionDispatch::IntegrationTest
  test "ward admin lists fichas and can read the year" do
    sign_in_ward
    get ward_fichas_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#ficha_index.hall-paper"
    assert_select ".hall-sheet"
    assert_select ".hall-still"
    assert_select "h1", "Fichas de la rama"
    assert_select "a", /Carmen/
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0
    get ward_ficha_path(people(:carmen_garcia))
    assert_response :success
    assert_select ".year-shout", "1833"
    assert_select ".merge-card .person-pick", text: /Carmen/
    assert_select ".merge-card .person-pick", text: /Pili/, count: 0
    assert_select ".merge-card", text: /#{Regexp.escape(I18n.t("street.merge_crowns", count: 208))}/
    assert_select "form[action=?] input[name=source_id][value=?]",
                  ward_ficha_merge_path(people(:carmen_garcia)), people(:carmen_lopez).id.to_s
  end

  test "ward admin edits and merges fichas" do
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
    people(:carmen_garcia).update_column(:created_at, 2.years.ago)
    source.update_column(:created_at, 1.year.ago)
    post ward_ficha_merge_path(people(:carmen_garcia)), params: { source_id: source.id }
    assert_redirected_to ward_ficha_path(people(:carmen_garcia))
    assert_not Person.exists?(source.id)
  end

  test "ward admin cannot merge people with different names" do
    sign_in_ward

    assert_no_difference("Person.count") do
      post ward_ficha_merge_path(people(:carmen_garcia)), params: { source_id: people(:pili).id }
    end

    assert_redirected_to ward_ficha_path(people(:carmen_garcia))
    assert Person.exists?(people(:pili).id)
  end

  test "ward admin merge keeps the oldest card even when opening the newer one" do
    sign_in_ward
    oldest = people(:carmen_garcia)
    newer = people(:carmen_lopez)
    oldest.update_column(:created_at, 2.years.ago)
    newer.update_column(:created_at, 1.year.ago)

    post ward_ficha_merge_path(newer), params: { source_id: oldest.id }

    assert_redirected_to ward_ficha_path(oldest)
    assert Person.exists?(oldest.id)
    assert_not Person.exists?(newer.id)
  end
end
