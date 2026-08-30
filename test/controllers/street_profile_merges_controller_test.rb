require "test_helper"

class StreetProfileMergesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    @source = people(:carmen_lopez)
    @keeper = people(:carmen_garcia)
    @source.update_column(:created_at, 1.year.ago)
    @keeper.update_column(:created_at, 2.years.ago)
    post street_profile_path, params: {
      person_id: @source.id,
      favorite_year: @source.favorite_year
    }
  end

  test "profile edit shows same-ward homonyms with avatar crowns and creation date" do
    get player_profile_path(@source, edit: "merge")

    assert_response :success
    assert_select ".profile-merge"
    assert_select ".person-pick", text: /#{@keeper.given_name}/
    assert_select ".person-pick img[src*=?]", @keeper.avatar_key
    assert_select "small", text: /#{Regexp.escape(I18n.t("street.merge_crowns", count: 208))}/
    assert_select "small", text: /#{I18n.l(@keeper.created_at.to_date)}/
    assert_select "form[action=?]", player_profile_merge_path(@source)
  end

  test "merges the new duplicate into the verified old profile" do
    assert_difference("Person.count", -1) do
      post player_profile_merge_path(@source), params: {
        person_id: @keeper.id,
        favorite_year: @keeper.favorite_year
      }
    end

    assert_redirected_to player_profile_path(@keeper)
    assert_not Person.exists?(@source.id)
    follow_redirect!
    assert_select ".banner", text: /#{@keeper.given_name}/
  end

  test "does not merge when the old profile verification fails" do
    assert_no_difference("Person.count") do
      post player_profile_merge_path(@source), params: {
        person_id: @keeper.id,
        favorite_year: 1999
      }
    end

    assert_redirected_to player_profile_path(@source, edit: "merge")
    assert Person.exists?(@source.id)
  end

  test "always keeps the oldest profile even when it is the current one" do
    @source.update_column(:created_at, 2.years.ago)
    @keeper.update_column(:created_at, 1.year.ago)

    assert_difference("Person.count", -1) do
      post player_profile_merge_path(@source), params: {
        person_id: @keeper.id,
        favorite_year: @keeper.favorite_year
      }
    end

    assert Person.exists?(@source.id)
    assert_not Person.exists?(@keeper.id)
    assert_redirected_to player_profile_path(@source)
  end

  test "does not merge through another player's URL" do
    assert_no_difference("Person.count") do
      post player_profile_merge_path(@keeper), params: {
        person_id: @keeper.id,
        favorite_year: @keeper.favorite_year
      }
    end

    assert_response :not_found
  end
end
