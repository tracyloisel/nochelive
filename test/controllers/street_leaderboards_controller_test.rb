require "test_helper"

class StreetLeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "leaderboard page paginates ward standings" do
    sign_in_congregation
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "liga-page",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-page"
    assert_select ".street-board"
  end

  test "guest can browse ward leaderboard without profile" do
    sign_in_congregation

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-search"
  end

  test "pack tab and search filter standings" do
    sign_in_congregation
    ward = wards(:demo)
    ana = ward.people.create!(given_name: "Anabel", avatar_key: "gato", favorite_year: 2021)
    QuizRun.create!(
      device_digest: "liga-ana",
      person: ana,
      pack_id: "coronas",
      position: 10,
      score: 42,
      status: "finished",
      opened_at: Time.current
    )

    get street_leaderboard_path(pack_id: "coronas", q: "Ana")
    assert_response :success
    assert_select ".street-board-row", text: /Anabel/
  end
end
