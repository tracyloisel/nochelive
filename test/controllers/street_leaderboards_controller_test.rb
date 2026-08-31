require "test_helper"

class StreetLeaderboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    sign_in_person(people(:pili))
  end

  test "liga renders the celestial light court summary" do
    get street_leaderboard_path

    assert_response :success
    assert_select "#street_world.liga-court:not(.is-full)[data-controller~='liga-board']"
    assert_select "h1", text: I18n.t("street.leaderboard_court_title")
    assert_select ".liga-court-heading > p", text: I18n.t("street.leaderboard_scope_stake_lede")
    assert_select ".liga-court-podium"
    assert_select ".liga-rivalry"
    assert_select ".liga-rivalry-cta" do
      assert_select ".liga-rivalry-cta-medallion .picto"
      assert_select ".liga-rivalry-cta-label"
      assert_select ".liga-rivalry-cta-arrow .picto"
    end
    assert_select ".liga-around"
    assert_select "a.liga-see-all[href*='view=full']", text: /#{Regexp.escape(I18n.t("street.leaderboard_full"))}/ do
      assert_select ".liga-see-all-medallion .picto"
      assert_select ".liga-see-all-label", text: I18n.t("street.leaderboard_full")
      assert_select ".liga-see-all-arrow .picto"
    end
    assert_select "a.liga-challenge-strip[href]"
    assert_select ".liga-full-panel", count: 0
    assert_select ".street-liga-you-bar", count: 0
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock"
    assert_select ".navigation-dock .navigation-dock__item.is-active[href=?]", root_path
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
    assert_select "#street_world.is-full"
    assert_select ".liga-court-podium", count: 0
    assert_select ".liga-court-list.is-full .liga-court-row", text: /Anabel/
    assert_select "#leaderboard_q[value=Ana]"
  end

  test "rival rows open a challenge scene with rank crowns and the real open pack" do
    rival = people(:carmen_garcia)
    open_run = QuizRun.create!(
      device_digest: "liga-open-rival",
      person: rival,
      pack_id: "milagros",
      position: 4,
      score: 27,
      status: "open",
      opened_at: Time.current
    )
    pack_title = open_run.pack.copy(:title)

    get street_leaderboard_path(view: "full", scope: "ward")

    assert_response :success
    assert_select "button[data-person-id='#{rival.id}']", count: 1 do |buttons|
      assert_equal pack_title, buttons.first["data-person-pack"]
      assert_equal I18n.t("street.leaderboard_pack_progress", position: 4, total: QuizDefinition::QUESTIONS_PER_PACK),
                   buttons.first["data-person-pack-progress"]
      assert_select ".liga-court-row-state.is-challenge", text: I18n.t("street.leaderboard_challenge_cta")
    end
    assert_select "dialog.street-liga-dialog[aria-labelledby=liga_duel_title]"
    assert_select ".liga-duel-intel [data-liga-board-target=friendRank]"
    assert_select ".liga-duel-intel [data-liga-board-target=friendScore]"
    assert_select ".liga-duel-intel [data-liga-board-target=friendPack][data-empty-label=?]", I18n.t("street.leaderboard_no_open_pack")
    assert_select ".liga-duel-profile-owner [data-liga-board-target=rivalProfileName]"
    assert_select ".liga-duel-notification-note[data-template=?]", I18n.t("street.leaderboard_notification_warning", name: "__RIVAL__")
    assert_select ".liga-duel-notification-note .picto", count: 0
    assert_select ".liga-duel-cta [data-liga-board-target=sendLabel]", text: I18n.t("street.leaderboard_challenge_cta")
    assert_select ".liga-duel-rules", count: 0
    assert_select ".street-liga-dialog", text: /#{Regexp.escape(I18n.t("duel_campus.sections.friends_lede"))}/, count: 0
  end

  test "search miss is honest" do
    finish_pack(people(:pili), score: 40)
    get street_leaderboard_path(q: "zzzq")

    assert_response :success
    assert_select ".liga-court-empty", text: I18n.t("street.leaderboard_empty_search")
  end

  test "unranked player is invited into an existing court" do
    newcomer = wards(:demo).people.create!(given_name: "Noa", avatar_key: "delfin", favorite_year: 2024)
    sign_in_person(newcomer)

    get street_leaderboard_path

    assert_response :success
    assert_select ".liga-court-podium"
    assert_select ".liga-rivalry-copy.is-unranked", text: /#{Regexp.escape(I18n.t("street.leaderboard_unranked_title"))}/
    assert_select ".street-liga-you-bar", count: 0
  end

  test "empty ward keeps the court useful without inventing players" do
    get ward_leaderboard_path("BLANK")

    assert_response :success
    assert_select ".liga-court-podium", count: 0
    assert_select ".liga-court-empty.is-hero", text: I18n.t("street.leaderboard_empty")
    assert_select ".liga-rivalry-copy.is-unranked"
    assert_select "a.liga-see-all"
  end

  test "ward visit stays scoped and same-stake wards are filter choices" do
    alicante = Ward.create!(
      name: "Rama Alicante", code: "ALICANTE", emblem: "paloma", city: "Alicante",
      country_code: "ES", listed: true, stake_unit_id: wards(:demo).stake_unit_id,
      admin_token_digest: GameSession.digest_token("rama-alicante")
    )
    lucas = alicante.people.create!(given_name: "Lucas", avatar_key: "gato", favorite_year: 2010)
    finish_pack(people(:pili), score: 55)
    finish_pack(lucas, score: 99)

    get ward_leaderboard_path("RAMA", view: "full")

    assert_response :success
    assert_select ".liga-scope-switch a.is-active", text: /Rama Benidorm/
    assert_select ".liga-court-row", text: /Pili/
    assert_select ".liga-court-row", text: /Lucas/, count: 0

    get ward_leaderboard_path("RAMA", view: "full", scope: "stake")

    assert_response :success
    assert_select ".liga-scope-switch a.is-active", text: I18n.t("street.leaderboard_scope_stake")
    assert_select ".liga-court-row", text: /Pili/
    assert_select ".liga-court-row", text: /Lucas/
    assert_select ".liga-court-row-person small", text: /Rama Benidorm/
    assert_select ".liga-court-row-person small", text: /Rama Alicante/
    assert_select ".liga-court-heading > p", text: I18n.t("street.leaderboard_scope_stake_lede")
  end

  test "full ranking is paginated in server rendered windows of one hundred" do
    105.times do |index|
      person = wards(:demo).people.create!(
        given_name: "Fenetre#{index.to_s.rjust(3, "0")}",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 1900 + (index % 100)
      )
      finish_pack(person, score: 1_000 - index)
    end

    get street_leaderboard_path(view: "full", q: "Fenetre")

    assert_response :success
    assert_select ".liga-court-list.is-full .liga-court-row", count: 100
    assert_select ".liga-cursor-link.is-next", text: I18n.t("street.leaderboard_next_group", count: 100)
    assert_select ".liga-cursor-link.is-prev", count: 0

    get street_leaderboard_path(view: "full", q: "Fenetre", cursor: 100)

    assert_response :success
    assert_select ".liga-court-list.is-full .liga-court-row", count: 5
    assert_select ".liga-cursor-link.is-prev", text: I18n.t("street.leaderboard_prev")
    assert_select ".liga-cursor-link.is-next", count: 0
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
