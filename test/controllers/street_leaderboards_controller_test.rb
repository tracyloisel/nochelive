require "test_helper"

class StreetLeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "leaderboard page paginates ward standings" do
    sign_in_congregation
    pili = people(:pili)
    run = QuizRun.create!(
      device_digest: "liga-page",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    3.times do |index|
      QuizAnswer.create!(
        quiz_run: run,
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: "liga-page-q-#{index}",
        choice_key: "a",
        correct: true
      )
    end
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-page"
    assert_select ".home-brand"
    assert_select "h1.street-hub-lockup-name", text: "Noche Live"
    assert_select "a.street-hub-lockup-wordmark[href=?]", root_path
    assert_select ".street-hub-kicker", text: I18n.t("street.leaderboard_kicker")
    assert_select ".street-leaderboard-sheet"
    assert_select ".street-leaderboard-tools"
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select ".street-liga-podium"
    assert_select ".street-liga-podium-slot.is-you.is-live .street-live-dot"
    assert_select ".street-liga-entry.is-you .street-board-answered", text: I18n.t("street.leaderboard_answered", count: 3)
    assert_select ".street-leaderboard-filter-mark .picto-podium"
    assert_select "form.street-leaderboard-search" do
      assert_select ".street-leaderboard-search-row + .street-leaderboard-filter"
    end
    assert_select ".street-leaderboard-select[data-action*='liga-search#queue']"
    assert_select ".street-leaderboard-tab", count: 0
    assert_select ".street-board"
    assert_select ".street-hub-nav", count: 0
    assert_select ".street-world-dock", count: 0
    assert_select "a.btn-gold", count: 0
    assert_select "a.quiet-link.street-leaderboard-duels", text: I18n.t("street.duel_inbox")
    assert_select "a.street-leaderboard-duels[href=?]", street_challenges_path
    assert_select ".street-leaderboard-ward", count: 0
    assert_select "a.street-leaderboard-ward-back", count: 0
  end

  test "guest can browse ward leaderboard without profile" do
    sign_in_congregation

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-search"
    assert_select "[data-controller~='liga-search']"
    assert_select ".street-leaderboard-select"
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select ".street-hub-nav", count: 0
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
    assert_select ".street-liga-podium", count: 0
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
    assert_select ".street-leaderboard-empty.is-search", text: I18n.t("street.leaderboard_empty_search")
    assert_select ".street-leaderboard-empty-mark .picto-search"
    assert_select "a.street-leaderboard-search-clear"
    assert_select ".street-leaderboard-empty", text: /todavía|yet|encore|ainda/, count: 0
  end

  test "shows a live dot only for people currently online" do
    sign_in_congregation
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    QuizRun.create!(
      device_digest: "liga-live-pili",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "liga-live-carmen",
      person: carmen,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    carmen.person_devices.update_all(last_seen_at: 1.hour.ago)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-liga-entry.is-you.is-live .street-live-dot"
    assert_select ".street-liga-entry", text: /Carmen/
    assert_select ".street-liga-entry.is-live", count: 1
    assert_select ".street-liga-entry:not(.is-live)", text: /Carmen/
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
    pili_run = QuizRun.create!(
      device_digest: "liga-pili-low",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 1,
      status: "finished",
      opened_at: Time.current
    )
    2.times do |index|
      QuizAnswer.create!(
        quiz_run: pili_run,
        device_digest: pili_run.device_digest,
        pack_id: pili_run.pack_id,
        question_id: "liga-pili-q-#{index}",
        choice_key: "a",
        correct: true
      )
    end
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_leaderboard_path
    assert_response :success
    assert_select ".street-leaderboard-sheet a.street-leaderboard-you-card", text: /Pili/
    assert_select ".street-liga-podium-slot.is-medal-1"
    assert_select ".street-board-row", minimum: 20
    assert_select ".street-leaderboard-you-card .street-live-dot"
    assert_select ".street-leaderboard-you-card .street-board-answered", text: I18n.t("street.leaderboard_answered", count: 2)
    assert_select ".street-leaderboard-you-card .street-board-rank"
    assert_select ".street-leaderboard-tools a.street-leaderboard-you-card[href*='page=2'][href*='liga-you']"
    assert_select ".street-card.street-leaderboard-you-card", count: 0
    assert_select ".street-board-row.is-you", count: 0
    assert_select ".street-board-gap", count: 0
    assert_select ".street-leaderboard-pages"
    assert_select "a.street-leaderboard-page-link[href*='page=2']", text: "2"
    assert_select "span.street-leaderboard-page-link.is-current[aria-current=page]", text: "1"
    assert_select "a.street-leaderboard-page-link.is-step[aria-label]"
    assert_select "form.street-leaderboard-search[onsubmit]", count: 0
    assert_select "a.btn-ghost", count: 0
    assert_select "a.btn-gold", count: 0

    get street_leaderboard_path(page: 2)
    assert_response :success
    assert_select ".street-leaderboard-you-card", count: 0
    assert_select "#liga-you.street-board-row.is-you.is-live", text: /Pili/
    assert_select "span.street-leaderboard-page-link.is-current[aria-current=page]", text: "2"
    assert_select "a.street-leaderboard-page-link", text: "1"
  end

  test "liga chrome sits on the hall without an ivory sheet" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    sheet = css[/\.street-leaderboard-sheet \{[^}]+\}/m]
    tools = css[/\.street-leaderboard-tools \{[^}]+\}/m]
    brand = css[/\.street-leaderboard-page \.home-brand \{[^}]+\}/m]
    name = css[/\.street-leaderboard-page \.home-brand h1,\n\.street-leaderboard-page \.street-hub-lockup-name \{[^}]+\}/m]
    assert sheet, "expected .street-leaderboard-sheet rule"
    assert tools, "expected .street-leaderboard-tools rule"
    assert brand, "expected liga brand rule"
    assert name, "expected liga lockup type rule"
    assert_match(/background: transparent/, sheet)
    assert_match(/background: transparent/, tools)
    assert_match(/background: transparent/, brand)
    assert_match(/font-size: 1\.18rem/, name)
    refute_match(/#fffef9/, sheet)
    refute_match(/#fffef9/, tools)
  end

  test "public rama liga is scoped to that ward" do
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "liga-rama-pili",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    marta = wards(:blank).people.create!(given_name: "Marta", avatar_key: "gato", favorite_year: 1999)
    QuizRun.create!(
      device_digest: "liga-rama-marta",
      person: marta,
      pack_id: "coronas",
      position: 10,
      score: 99,
      status: "finished",
      opened_at: Time.current
    )

    get ward_leaderboard_path("RAMA")
    assert_response :success
    assert_select ".street-leaderboard-page"
    assert_select ".street-hub-kicker", text: "Rama Benidorm"
    assert_select ".street-leaderboard-ward", count: 0
    assert_select "a.street-leaderboard-ward-back[href=?]", ward_profile_path("RAMA"),
          text: I18n.t("street.leaderboard_back_ward")
    assert_select "form.street-leaderboard-search[action=?]", ward_leaderboard_path("RAMA")
    assert_select ".street-liga-entry", text: /Pili/
    assert_select ".street-liga-entry", text: /Marta/, count: 0
    assert_select "a.street-leaderboard-duels", count: 0
    assert_select "a.btn-gold", count: 0
  end

  test "visiting another rama liga does not mark you or show duels" do
    sign_in_congregation
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "liga-visit-pili",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    marta = wards(:blank).people.create!(given_name: "Marta", avatar_key: "gato", favorite_year: 1999)
    QuizRun.create!(
      device_digest: "liga-visit-marta",
      person: marta,
      pack_id: "coronas",
      position: 10,
      score: 12,
      status: "finished",
      opened_at: Time.current
    )

    get ward_leaderboard_path("BLANK")
    assert_response :success
    assert_select ".street-hub-kicker", text: "Rama vacía"
    assert_select ".street-leaderboard-ward", count: 0
    assert_select "a.street-leaderboard-ward-back[href=?]", ward_profile_path("BLANK"),
          text: I18n.t("street.leaderboard_back_ward")
    assert_select ".street-liga-entry", text: /Marta/
    assert_select ".street-liga-entry", text: /Pili/, count: 0
    assert_select ".is-you", count: 0
    assert_select "a.street-leaderboard-duels", count: 0
  end

  test "unknown rama liga redirects home" do
    get ward_leaderboard_path("NOPE")
    assert_redirected_to root_path
    assert_equal I18n.t("errors.people.ward_missing"), flash[:alert]
  end

  test "empty rama liga names the chapel" do
    get ward_leaderboard_path("BLANK")
    assert_response :success
    assert_select ".street-hub-kicker", text: "Rama vacía"
    assert_select ".street-leaderboard-empty", text: I18n.t("street.leaderboard_empty_ward")
    assert_select "a.street-leaderboard-ward-back", text: I18n.t("street.leaderboard_back_ward")
    assert_select "a.btn-gold", count: 0
  end
end
