require "test_helper"

class WardProfilesControllerTest < ActionDispatch::IntegrationTest
  test "localized Benidorm profile is indexable with search variants and alternates" do
    get localized_ward_profile_path(locale: "en", ward_section: "latter-day-saints", slug: "benidorm")

    assert_response :success
    assert_select "html[lang=en]"
    assert_select "title", text: "LDS Benidorm | Latter-day Saints in Benidorm"
    assert_select "h1", text: "A place to come, learn, and grow together.", count: 1
    assert_select ".rama-community-mark", text: /Benidorm BRANCH/
    assert_select "meta[name=robots][content^='index, follow']"
    assert_select "meta[name=description][content*='Church of Jesus Christ']"
    assert_select "link[rel=canonical][href$='/en/latter-day-saints/benidorm']"
    assert_select "link[rel=alternate][hreflang=es][href$='/es/santos-de-los-ultimos-dias/benidorm']"
    assert_select "link[rel=alternate][hreflang=fr][href$='/fr/saints-des-derniers-jours/benidorm']"
    assert_select "link[rel=alternate][hreflang=pt-br][href$='/pt-br/santos-dos-ultimos-dias/benidorm']"
    assert_select "script[type='application/ld+json']", text: /LDS Benidorm/
  end

  test "public profile tells one linear community story and keeps shared chrome" do
    create_current_week!

    get ward_profile_path("RAMA")

    assert_response :success
    manifest = JSON.parse(css_select("#noche_resource_manifest").first.text)
    assert_includes manifest.fetch("styles"), "rama"
    assert_includes manifest.fetch("controllers"), "rama-motion"
    refute_includes manifest.fetch("controllers"), "hub-countdown"
    assert_select "link[href*='surfaces/rama'][data-turbo-track='dynamic']", count: 1
    assert_select "#rama_profile.rama-page[data-controller='rama-motion']"
    assert_select "#rama_profile > section" do |sections|
      assert_equal %w[rama-story-hero rama-week rama-story-night rama-league rama-story-visit],
        sections.map { |section| section["class"].split.find { |name| name.in?(%w[rama-story-hero rama-week rama-story-night rama-league rama-story-visit]) } }
    end

    assert_select ".rama-community-mark", text: /RAMA Benidorm/
    assert_select "h1", text: "Un lugar para venir, aprender y crecer juntos.", count: 1
    assert_select ".rama-story-hero__address", text: /Avinguda Alfonso Puchades, 27 · Benidorm/
    assert_select ".rama-story-hero__actions a", count: 3
    assert_select ".rama-story-hero__actions a[href*='google.com/maps']"
    assert_select ".rama-week", text: /Psalms this week/
    assert_select ".rama-story-night", count: 1
    assert_select ".rama-story-night a[href=?]", night_path("DAVID")
    assert_select ".rama-story-night", text: /Noche Live/
    assert_select ".rama-player", text: /Pili/
    assert_select ".rama-story-visit a[href*='google.com/maps']"

    assert_select ".rama-circle", count: 0
    assert_select ".rama-countdown, [data-controller~='hub-countdown']", count: 0
    assert_select ".rama-next-players, .rama-stats, .rama-events, .rama-live-carousel, .rama-card", count: 0
    assert_select "nav.home-menu"
    assert_select ".chrome-drawer a[href=?]", about_path
    assert_select ".chrome-drawer a[href=?]", ward_profile_path("RAMA")
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
    assert_select ".navigation-dock__item[href=?] > .picto-scripture-book", scripture_library_path
  end

  test "guest never receives Circle content" do
    ward = wards(:demo)
    ward.update!(scripture_circle_mode: "active")
    week = create_current_week!(references: [ "ot/ps/102" ])
    publish_question(week:, body: "¿Por qué parece tan larga la espera?")

    get ward_profile_path("RAMA")

    assert_response :success
    assert_select ".rama-circle", count: 0
    assert_not_includes response.body, "¿Por qué parece tan larga la espera?"
    assert_not_includes response.body, people(:carmen_garcia).display_name
  end

  test "member sees a graceful empty Circle when the week has no conversation" do
    ward = wards(:demo)
    ward.update!(scripture_circle_mode: "active")
    create_current_week!(references: [ "ot/ps/102" ])
    sign_in_person(people(:pili))

    get ward_profile_path("RAMA")

    assert_response :success
    assert_select ".rama-circle", count: 1
    assert_select ".rama-circle-empty", text: /Aún no hay conversaciones esta semana/
    assert_select ".rama-conversation", count: 0
    assert_select ".rama-circle__privacy", count: 0
  end

  test "member sees two real weekly Circle conversations with safe counts" do
    ward = wards(:demo)
    ward.update!(scripture_circle_mode: "active")
    week = create_current_week!(references: %w[ot/ps/102 ot/ps/110])
    first = publish_question(week:, reference: "ot/ps/102", body: "¿Por qué parece tan larga la espera?")
    publish_question(week:, reference: "ot/ps/110", body: "Nunca había visto a Melquisedec aquí.")
    first.scripture_circle_thread.scripture_circle_posts.create!(
      ward:,
      person: people(:pili),
      parent: first,
      kind: "reply",
      locale: "es",
      body: "Yo también me lo pregunto."
    )
    sign_in_person(people(:pili))

    get ward_profile_path("RAMA")

    assert_response :success
    assert_select ".rama-circle", count: 1
    assert_select ".rama-conversation", count: 2
    assert_select ".rama-conversation", text: /¿Por qué parece tan larga la espera?/
    assert_select ".rama-conversation", text: /Nunca había visto a Melquisedec aquí/
    assert_select ".rama-conversation__reply", text: /1 respuesta/
    assert_select ".rama-circle__privacy", text: /Solo los miembros de esta comunidad/
  end

  test "read-only Circle opens published conversations without inviting a reply" do
    ward = wards(:demo)
    ward.update!(scripture_circle_mode: "read_only")
    week = create_current_week!(references: [ "ot/ps/102" ])
    publish_question(week:, body: "¿Por qué parece tan larga la espera?")
    sign_in_person(people(:pili))

    get ward_profile_path("RAMA")

    assert_response :success
    assert_select ".rama-conversation__reply", text: /Abrir la conversación/
    assert_select ".rama-conversation__reply", text: /Responder/, count: 0
  end

  test "read-only Circle empty state does not ask the member to publish" do
    ward = wards(:demo)
    ward.update!(scripture_circle_mode: "read_only")
    create_current_week!(references: [ "ot/ps/102" ])
    sign_in_person(people(:pili))

    get ward_profile_path("RAMA")

    assert_response :success
    assert_select ".rama-circle-empty", text: /El Círculo aún está tranquilo esta semana/
    assert_select ".rama-circle-empty", text: /haz la primera pregunta/, count: 0
  end

  test "host without a live night keeps the narrative invitation and empty league" do
    sign_in_ward(wards(:blank), token: "rama-blank")

    get ward_profile_path("BLANK")

    assert_response :success
    assert_select ".rama-story-night", count: 0
    assert_select ".rama-story-visit", count: 1
    assert_select ".rama-league-empty", text: /Madrid/
    assert_select ".navigation-dock__item[href=?] > .picto-scripture-book", scripture_library_path
  end

  test "league rail only shows players from this ward" do
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
    assert_select ".rama-player", text: /Pili/
    assert_select ".rama-player", text: /Marta/, count: 0
    assert_select ".rama-league__foot a[href=?]", ward_leaderboard_path("RAMA")
  end

  test "congregation cookie does not open fichas" do
    sign_in_congregation
    get ward_fichas_path
    assert_redirected_to ward_profile_path("RAMA")
  end

  private

    def create_current_week!(references: [ "Psalms this week" ])
      program = StudyProgram.create!(
        slug: "ward-story-#{SecureRandom.hex(6)}",
        title: "Come, Follow Me #{Date.current.year}",
        year: Date.current.year + 10,
        canon: "old_testament",
        locale: "es",
        status: "published",
        source_url: "https://example.test/ward-story"
      )
      program.study_units.create!(
        slug: "week-current",
        kind: "week",
        position: 1,
        title: "Esta semana: Psalms this week",
        source_url: "https://example.test/ward-story/week",
        starts_on: Date.current.beginning_of_week,
        ends_on: Date.current.end_of_week,
        scripture_refs: references,
        status: "published"
      )
    end

    def publish_question(week:, reference: nil, body:)
      reference ||= week.scripture_refs.first
      thread = wards(:demo).scripture_circle_threads.find_or_create_by!(reference:)
      thread.scripture_circle_posts.create!(
        ward: wards(:demo),
        person: people(:carmen_garcia),
        kind: "question",
        locale: "es",
        body:
      )
    end

    def sign_in_person(person, token: "ward-story-device")
      person.person_devices.find_or_create_by!(device_token: token)
      set_signed_cookie(:noche_device, token)
      set_signed_cookie(:noche_ward, person.ward_id)
      set_signed_cookie(:noche_street_person, person.id)
    end

    def set_signed_cookie(name, value)
      signed_value = signed_cookie_jar.tap { |jar| jar.signed[name] = value }[name]
      uri = URI("http://#{host}/")
      cookies.merge("#{name}=#{Rack::Utils.escape(signed_value)}; path=/", uri)
    end

    def signed_cookie_jar(values = {})
      ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, values)
    end
end
