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
    assert_select ".street-leaderboard-sheet"
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select ".street-board-row.is-you"
    assert_select ".street-leaderboard-select"
    assert_select ".street-leaderboard-tab", count: 0
    assert_select ".street-board"
    assert_select ".street-hub-nav-item", count: 5
    assert_select ".street-hub-nav-item.is-active", text: /ranking|classement|clasificación/i
    assert_select "a.btn-gold", count: 0
  end

  test "guest can browse ward leaderboard without profile" do
    sign_in_congregation

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-search"
    assert_select "[data-controller~='liga-search']"
    assert_select ".street-leaderboard-select"
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select ".street-hub-nav"
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
    assert_select ".street-leaderboard-select option[value=coronas][selected]"
    assert_select ".street-board-row", text: /Anabel/
    assert_select "a.street-leaderboard-search-clear"
    assert_select ".street-leaderboard-search-row.is-filled"
    assert_select "#leaderboard_q[autofocus]"
  end

  test "missed name search explains itself and can be cleared" do
    sign_in_congregation
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "liga-miss",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )

    get street_leaderboard_path(q: "zzzq")
    assert_response :success
    assert_select ".street-board-row", count: 0
    assert_select ".street-leaderboard-empty", text: I18n.t("street.leaderboard_empty_search")
    assert_select ".street-leaderboard-empty-mark"
    assert_select "a.street-leaderboard-search-clear"
    assert_select ".street-leaderboard-empty", text: /todavía|yet|encore|ainda/, count: 0
  end

  test "you card appears when rank sits off the current page" do
    sign_in_congregation
    ward = wards(:demo)
    pili = people(:pili)
    25.times do |index|
      person = ward.people.create!(
        given_name: "Lead#{index}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 2000 + index
      )
      QuizRun.create!(
        device_digest: "liga-lead-#{index}",
        person:,
        pack_id: "coronas",
        position: 10,
        score: 200 - index,
        status: "finished",
        opened_at: Time.current
      )
    end
    QuizRun.create!(
      device_digest: "liga-pili-low",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 1,
      status: "finished",
      opened_at: Time.current
    )
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-sheet .street-leaderboard-you-card", text: /Pili/
    assert_select ".street-card.street-leaderboard-you-card", count: 0
    assert_select ".street-board-row.is-you", count: 0
    assert_select ".street-board-gap", count: 0
    assert_select ".street-leaderboard-pages"
    assert_select "a.street-leaderboard-page-link"
    assert_select "a.btn-ghost", count: 0
    assert_select "a.btn-gold", count: 0

    get street_leaderboard_path(page: 2)
    assert_response :success
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select ".street-board-row.is-you", text: /Pili/
  end
end
