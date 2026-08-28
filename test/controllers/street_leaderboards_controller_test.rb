require "test_helper"

class StreetLeaderboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    sign_in_person(people(:pili))
  end

  test "liga renders the celestial living board" do
    get street_leaderboard_path

    assert_response :success
    assert_select "#street_world.street-leaderboard-page[data-controller~='liga-board']"
    assert_select "a.street-liga-rama-back[href=?]", ward_profile_path("RAMA"), text: I18n.t("street.leaderboard_back_ward")
    assert_select "h1", text: I18n.t("street.leaderboard_screen_title")
    assert_select "a.street-liga-sibling-link[href=?]", street_challenges_path
    assert_select ".street-liga-scope a", count: 2
    assert_select ".street-liga-scope a", text: I18n.t("street.leaderboard_scope_stake")
    assert_select ".street-liga-filter-button", count: 0
    assert_select ".street-liga-filters-dialog", count: 0
    assert_select ".street-leaderboard-select", count: 0
    assert_select ".street-liga-podium"
    assert_select ".street-liga-entry .street-board-joined", minimum: 1
    assert_select ".street-liga-entry[data-liga-person-id=?] .street-board-joined",
                  people(:pili).id.to_s,
                  text: I18n.t("street.leaderboard_joined", date: I18n.l(people(:pili).created_at.to_date))
    assert_select ".street-liga-challenge-label", text: /#{Regexp.escape(I18n.t("street.duel_send"))}/, minimum: 1
    assert_select ".street-liga-you-bar"
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock"
    assert_select ".navigation-dock .navigation-dock__item.is-active[href=?]", root_path

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_match(/\.navigation-dock \{[^}]*left: 0;[^}]*right: 0;[^}]*width: auto;/m, css)
    refute_includes css, "--navigation-dock-width"
    assert_select "a[href^=?]", ward_fichas_path, count: 0
  end

  test "ward presenter can open profile management from the leaderboard" do
    sign_in_ward

    get street_leaderboard_path(q: "Carmen")

    assert_response :success
    assert_select "a[href=?]", ward_fichas_path(q: "Carmen"), text: I18n.t("fichas.leaderboard_manage")
  end

  test "player without a ward is asked to choose one then returns to the leaderboard" do
    reset!
    post street_profile_path, params: { name: "Noa", avatar_key: "delfin" }
    assert_redirected_to root_path

    get street_leaderboard_path
    assert_redirected_to search_path(cambiar: 1)
    assert_equal I18n.t("flashes.ward_required_social"), flash[:alert]

    post street_ward_pick_path, params: { code: wards(:demo).code }
    assert_redirected_to street_leaderboard_path
  end

  test "pack and name search render results as a list without the podium" do
    ana = wards(:demo).people.create!(given_name: "Anabel", avatar_key: "gato", favorite_year: 2021)
    finish_pack(ana, score: 42)

    get street_leaderboard_path(pack_id: "coronas", q: "Ana")

    assert_response :success
    assert_select ".street-liga-podium", count: 0
    assert_select ".street-board-rows .street-board-row.street-liga-entry", text: /Anabel/
    assert_select "#leaderboard_q[value=Ana]"
  end

  test "search miss is honest" do
    finish_pack(people(:pili), score: 40)
    get street_leaderboard_path(q: "zzzq")

    assert_response :success
    assert_select ".street-leaderboard-empty.is-search", text: I18n.t("street.leaderboard_empty_search")
  end

  test "ward visit stays scoped and same-stake wards are filter choices" do
    alicante = Ward.create!(
      name: "Rama Alicante", code: "ALICANTE", emblem: "paloma", city: "Alicante",
      country_code: "ES", listed: true, stake_unit_id: wards(:demo).stake_unit_id,
      presenter_token_digest: GameSession.digest_token("rama-alicante")
    )
    lucas = alicante.people.create!(given_name: "Lucas", avatar_key: "gato", favorite_year: 2010)
    finish_pack(people(:pili), score: 55)
    finish_pack(lucas, score: 99)

    get ward_leaderboard_path("RAMA")

    assert_response :success
    assert_select ".street-liga-scope", text: /Rama Benidorm/
    assert_select ".street-liga-entry", text: /Pili/
    assert_select ".street-liga-entry", text: /Lucas/, count: 0

    get ward_leaderboard_path("RAMA", scope: "stake")

    assert_response :success
    assert_select ".street-liga-scope a.is-active", text: I18n.t("street.leaderboard_scope_stake")
    assert_select ".street-liga-entry", text: /Pili/
    assert_select ".street-liga-entry", text: /Lucas/
    assert_select ".street-liga-player-ward", text: /Rama Benidorm/
    assert_select ".street-liga-player-ward", text: /Rama Alicante/
    assert_select ".street-liga-lede", text: I18n.t("street.leaderboard_basis_stake")
  end

  test "unknown ward redirects home" do
    get ward_leaderboard_path("NOPE")
    assert_redirected_to root_path
  end

  private

    def sign_in_person(person)
      post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
      follow_redirect!
    end

    def finish_pack(person, score:)
      QuizRun.create!(
        device_digest: "liga-#{person.id}-#{score}",
        person:,
        pack_id: "coronas",
        position: 10,
        score:,
        status: "finished",
        opened_at: Time.current
      )
    end
end
