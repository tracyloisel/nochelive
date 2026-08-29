require "test_helper"

class WardProfilesControllerTest < ActionDispatch::IntegrationTest
  test "localized Benidorm profile is indexable with search variants and alternates" do
    get localized_ward_profile_path(locale: "en", ward_section: "latter-day-saints", slug: "benidorm")

    assert_response :success
    assert_select "html[lang=en]"
    assert_select "title", text: "LDS Benidorm | Latter-day Saints in Benidorm"
    assert_select "h1", text: "LDS Benidorm"
    assert_select "meta[name=robots][content^='index, follow']"
    assert_select "meta[name=description][content*='Church of Jesus Christ']"
    assert_select "link[rel=canonical][href$='/en/latter-day-saints/benidorm']"
    assert_select "link[rel=alternate][hreflang=es][href$='/es/santos-de-los-ultimos-dias/benidorm']"
    assert_select "link[rel=alternate][hreflang=fr][href$='/fr/saints-des-derniers-jours/benidorm']"
    assert_select "link[rel=alternate][hreflang=pt-br][href$='/pt-br/santos-dos-ultimos-dias/benidorm']"
    assert_select "script[type='application/ld+json']", text: /LDS Benidorm/
  end

  test "public profile shows the Benidorm chapel pin and one gold live door" do
    get ward_profile_path("RAMA")
    assert_response :success
    assert_select "h1", text: "Rama Benidorm"
    assert_select "a.rama-pin[href*='Alfonso']"
    assert_select "a.rama-pin[href*='Benidorm']"
    assert_select "body.is-paper-hall"
    assert_select "#rama_profile.hall-paper"
    assert_select ".hall-sheet", count: 0
    assert_select ".hall-still"
    assert_select "a.rama-pin[href*='google.com/maps']"
    assert_select ".btn.btn-gold", text: /Entrar/
    assert_select ".btn.btn-gold", count: 1
    assert_select "a.quiet-link", text: /Solo ver/
    assert_select ".btn.btn-gold", text: /Solo ver/, count: 0
    assert_select "nav.home-menu"
    assert_select ".chrome-drawer a[href=?]", about_path
    assert_select ".chrome-drawer a[href=?]", ward_profile_path("RAMA")
    assert_select ".rama-cta a", text: /Otra rama/, count: 0
    assert_select ".btn.btn-gold", text: /Abrir la noche/, count: 0
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0
    assert_select "p.skip", count: 0
    assert_select ".rama-grid", count: 0
    assert_select ".rama-next a[href=?]", night_name_path("DAVID")
    assert_select "ul.rama-nights"
    assert_select "a.rama-night", count: 1
    assert_select "a.rama-night[href=?]", night_name_path("ELIAS")
    assert_select ".rama-last a[href=?]", ward_memory_path("RAMA", "QUIT")
    assert_select ".rama-last", text: /#{Regexp.escape(I18n.l(game_sessions(:cerrada).starts_at.to_date))}/
    assert_select ".rama-visit a[href*='google.com/maps']"
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
    assert_select ".navigation-dock__item[href=?] > .picto-scripture-book", study_program_path
    assert_select "a.rama-liga.street-league[href=?]", ward_leaderboard_path("RAMA")
    assert_select ".rama-liga .street-league-head h2", text: I18n.t("street.world_league")
    assert_select ".rama-liga .street-league-slot", text: /Pili/
    assert_select ".rama-liga-empty", count: 0
    assert_select ".rama-liga .street-league-all", text: I18n.t("ward.see_full_ranking")
    assert_select ".rama-stats", text: /#{Regexp.escape(I18n.t("street.leaderboard_players", count: 2))}/
    assert_select ".rama-cta a.quiet-link[href=?]", ward_leaderboard_path("RAMA"), count: 0
    assert_select ".rama-next .btn.btn-gold", count: 1
    assert_select ".btn.btn-gold", count: 1
  end

  test "host without a live night gets Abrir la noche as the gold CTA" do
    sign_in_ward(wards(:blank), token: "rama-blank")
    get ward_profile_path("BLANK")
    assert_response :success
    assert_select ".btn.btn-gold", text: /Abrir la noche/
    assert_select ".btn.btn-gold", count: 1
    assert_select ".btn.btn-gold", text: /Entrar/, count: 0
    assert_select ".rama-cta a.quiet-link[href=?]", ward_leaderboard_path("BLANK"), count: 0
    assert_select "a.rama-liga.street-league[href=?]", ward_leaderboard_path("BLANK")
    assert_select ".rama-liga-empty", text: I18n.t("street.leaderboard_empty_ward")
    assert_select ".navigation-dock__item[href=?] > .picto-scripture-book", study_program_path
  end

  test "rama liga tile shows this ward podium" do
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "rama-liga-pili",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    marta = wards(:blank).people.create!(given_name: "Marta", avatar_key: "gato", favorite_year: 1999)
    QuizRun.create!(
      device_digest: "rama-liga-marta",
      person: marta,
      pack_id: "coronas",
      position: 10,
      score: 99,
      status: "finished",
      opened_at: Time.current
    )

    get ward_profile_path("RAMA")
    assert_response :success
    assert_select "a.rama-liga.street-league[href=?]", ward_leaderboard_path("RAMA")
    assert_select ".rama-liga .street-league-slot", text: /Pili/
    assert_select ".rama-liga .street-league-slot", text: /Marta/, count: 0
    assert_select ".rama-liga-empty", count: 0
    assert_select ".rama-stats", text: /#{Regexp.escape(I18n.t("street.leaderboard_players", count: 2))}/
    assert_select ".btn.btn-gold", count: 1
  end

  test "congregation cookie does not open fichas" do
    sign_in_congregation
    get ward_fichas_path
    assert_redirected_to ward_profile_path("RAMA")
  end
end
