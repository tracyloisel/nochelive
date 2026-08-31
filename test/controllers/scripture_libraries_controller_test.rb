require "test_helper"

class ScriptureLibrariesControllerTest < ActionDispatch::IntegrationTest
  ROWS = %w[resume recommendation weekly bookmarks collection rama annual].freeze

  test "preview exposes seven purposeful intentions and one primary action" do
    get scripture_library_path(preview: 1, locale: :fr)

    assert_response :success
    assert_select "body.is-scripture-library.is-celestial-dark"
    assert_select ".scripture-library__hero h1", text: "Bibliothèque"
    assert_select ".scripture-library__world picture img", count: 1
    assert_select "form#recherche-ecritures[action='#{scripture_library_search_path}'][method=get]"
    assert_select "input[role=combobox][aria-controls=scripture-library-suggestions]"
    assert_select ".scripture-library-row", count: 7
    assert_select ".scripture-library-row.is-priority[data-library-row='resume']", count: 1
    assert_select ".scripture-library-row.is-priority .scripture-library-row__intent", count: 1
    assert_select ".scripture-library-row[data-library-row='recommendation']", text: /1 Néphi 5:1/
    assert_select ".scripture-library-row[data-library-row='weekly'] [role='progressbar'][aria-valuenow='58']"
    assert_select ".navigation-dock__item.is-active[href='#{scripture_library_path}']", text: "Bibliothèque"

    ROWS.each { |row| assert_select ".scripture-library-row[data-library-row='#{row}']", count: 1 }
    assert_select ".scripture-library-row[href='#{scripture_library_path}']", count: 0
    assert_select ".scripture-library-row[data-library-row='resume'][href^='/escrituras/'][href*='locale=fr']", count: 1
    assert_select ".scripture-library-row[data-library-row='recommendation'][href^='/escrituras/'][href*='locale=fr']", count: 1
    assert_select ".scripture-library-row[data-library-row='rama'].is-disabled[aria-disabled='true']", count: 1
    assert_select ".scripture-library-row[data-library-row='rama'][href]", count: 0
    assert_select ".scripture-library-row[href*='locale=fr']", count: 6
  end

  test "a visitor still gets seven useful choices without fabricated personal data" do
    get scripture_library_path(locale: :fr)

    assert_response :success
    assert_select ".scripture-library-row", count: 7
    assert_select ".scripture-library-row.has-primary-action[data-library-row='resume'][href*='section=canon']", count: 1
    assert_select ".scripture-library-row[data-library-row='resume'] .scripture-library-row__label", text: "Commencer à lire"
    assert_select ".scripture-library-row[href='#{scripture_library_path}']", count: 0
    assert_select ".scripture-library-row[data-library-row='collection'][href*='section=canon'][href*='locale=fr']", count: 1
    assert_select ".scripture-library-row[data-library-row='rama'].is-disabled[aria-disabled='true']",
      text: /#{Regexp.escape(I18n.t("scripture_library.rama.unavailable", locale: :fr))}/, count: 1
  end

  test "the honest first action and Circle label stay native in every supported language" do
    {
      es: [ "Empezar a leer", "Mi Círculo" ],
      fr: [ "Commencer à lire", "Mon Cercle" ],
      en: [ "Start reading", "My Circle" ],
      "pt-BR": [ "Comece a ler", "Meu Círculo" ]
    }.each do |locale, (start_label, circle_label)|
      get scripture_library_path(locale:)

      assert_response :success
      assert_select ".scripture-library-row[data-library-row='resume'] .scripture-library-row__label", text: start_label
      assert_select ".scripture-library-row[data-library-row='rama'] .scripture-library-row__label", text: circle_label
    end
  end

  test "a signed in reader sees real progress and bookmarks as reader destinations" do
    person = people(:pili)
    person.ward.update!(scripture_circle_mode: "active")
    sign_in_person(person)
    person.scripture_reading_progresses.create!(
      reference: "ot/1-sam/16", locale: "fr", first_opened_at: 2.days.ago,
      last_opened_at: 1.hour.ago, last_verse: 13, progress_ratio: 0.42
    )
    person.scripture_marks.create!(
      reference: "ot/1-sam/16", locale: "fr", anchor_scope: "passage", visual_style: "none",
      start_verse: 13, start_offset: 0, end_verse: 13, end_offset: 12,
      selected_text: "Samuel prit la corne d’huile", bookmarked_at: 30.minutes.ago
    )

    get scripture_library_path(locale: :fr)
    assert_response :success
    assert_select ".scripture-library-row[data-library-row='resume'][href^='/escrituras/ot/1-sam/16'][href*='locale=fr']", count: 1
    assert_select ".scripture-library-row[data-library-row='rama'][href='#{scripture_circle_path(locale: :fr)}']", count: 1

    get scripture_library_path(locale: :fr, section: "bookmarks", anchor: "selection")
    assert_response :success
    assert_select ".scripture-library-row[data-library-row='bookmarks'][aria-current='true'] + turbo-frame#library_selection", count: 1 do
      assert_select ".scripture-library-selection", count: 1
      assert_select "a.scripture-library-selection__item[href^='/escrituras/ot/1-sam/16'][href*='locale=fr'][data-turbo-frame='_top']", minimum: 1
    end
  end

  test "deep links render weekly bookmark canon and program choices without javascript" do
    {
      weekly: { section: "weekly", unit: "preview" },
      bookmarks: { section: "bookmarks" },
      collection: { section: "canon", collection: "old_testament" },
      annual: { section: "program", unit: "preview" }
    }.each do |row, query|
      get scripture_library_path(**query, preview: 1, locale: :fr, anchor: "selection")

      assert_response :success
      assert_select ".scripture-library-row[data-library-row='#{row}'][aria-current='true'] + turbo-frame#library_selection", count: 1 do
        assert_select ".scripture-library-selection", count: 1
      end
      assert_select ".scripture-library-selection__item", minimum: 1
    end
  end

  test "a selection keeps links inside real list items and offers a return control" do
    get scripture_library_path(section: "weekly", unit: "preview", preview: 1, locale: :fr, anchor: "selection")

    assert_response :success
    assert_select "#selection [data-library-selection-close][href='#choisir-lecture']",
      text: I18n.t("scripture_library.selection.close", locale: :fr), count: 1
    assert_select "#scripture-library-selection-items[role=list] > li.scripture-library-selection__list-item[role=listitem]", minimum: 1
    assert_select "#scripture-library-selection-items > li[role=listitem] > a.scripture-library-selection__item", minimum: 1
    assert_select "#scripture-library-selection-items a[role=listitem]", count: 0
  end

  test "a canon deep link drills from a book to reader chapters without another page" do
    get scripture_library_path(
      section: "canon", collection: "old_testament", book: "ot/ps",
      preview: 1, locale: :fr, anchor: "selection"
    )

    assert_response :success
    assert_select ".scripture-library-row[data-library-row='collection'][aria-current='true'] + turbo-frame#library_selection", count: 1 do
      assert_select ".scripture-library-selection", count: 1
      assert_select ".scripture-library-selection__breadcrumbs > span[aria-current='page'] b", text: "Psaumes", count: 1
      assert_select "a.scripture-library-selection__item[href^='/escrituras/ot/ps/'][href*='locale=fr'][data-turbo-frame='_top']", minimum: 1
    end
    assert_select "a[href^='/fr/bible/psaumes']", count: 0
  end

  test "an exact chapter or verse search redirects to the reader without javascript" do
    get scripture_library_search_path, params: { q: "DyC 48", locale: :fr }

    assert_response :see_other
    assert_redirected_to scripture_path("dc-testament/dc/48", cite: "Doctrine et Alliances 48", locale: :fr)

    get scripture_library_search_path, params: { q: "Jean 3:16-17", locale: :fr }
    assert_response :see_other
    assert_redirected_to scripture_path("nt/john/3", cite: "Jean 3:16–17", locale: :fr)
  end

  test "a book search offers an inline chapter chooser and invalid input stays accessible" do
    get scripture_library_search_path, params: { q: "Psaumes", locale: :fr }
    assert_response :see_other
    assert_redirected_to scripture_library_path(
      section: "canon", collection: "old_testament", book: "ot/ps", locale: :fr, anchor: "selection"
    )
    follow_redirect!
    assert_response :success
    assert_select ".scripture-library-row[data-library-row='collection'][aria-current='true'] + turbo-frame#library_selection .scripture-library-selection", count: 1

    get scripture_library_search_path, params: { q: "Jean 99", locale: :fr }
    assert_response :unprocessable_entity
    assert_select "#scripture-library-search-status[role=status]", text: /n’existe pas/

    get scripture_library_search_path, params: { q: "Jean 3:99", locale: :fr }
    assert_response :unprocessable_entity
    assert_select "#scripture-library-search-status[role=status]", text: /n’existe pas/
  end

  test "autocomplete preserves the inline target for books and the reader target for passages" do
    get scripture_library_search_path, params: { q: "Psaumes", locale: :fr, suggest: 1 }

    assert_response :success
    assert_not_includes response.body, "<html"
    assert_not_includes response.body, "scripture-library__world"
    assert_select "#scripture-library-suggestions[role=listbox]" do
      assert_select "a[role=option][href*='section=canon'][href*='locale=fr'][data-turbo-frame='library_selection'][data-turbo-action='advance']", count: 1
    end

    get scripture_library_search_path, params: { q: "Jean 3:16", locale: :fr, suggest: 1 }

    assert_response :success
    assert_select "#scripture-library-suggestions[role=listbox]" do
      assert_select "a[role=option][href^='/escrituras/nt/john/3'][href*='locale=fr'][data-turbo-frame='_top'][data-action*='scripture-launcher#prepare']", count: 1
    end
  end

  test "legacy reading selectors redirect to equivalent library deep links" do
    get study_program_path(locale: :fr)
    assert_redirected_to scripture_library_path(locale: :fr, section: "program", anchor: "selection")
    get study_history_path(locale: :fr)
    assert_redirected_to scripture_library_path(locale: :fr, section: "bookmarks", anchor: "selection")
    get study_community_path(ward_code: "someone-elses-rama", locale: :fr)
    assert_redirected_to scripture_circle_path(locale: :fr)

    get study_unit_path(4242, locale: :fr)
    assert_redirected_to scripture_library_path(locale: :fr, section: "weekly", unit: 4242, anchor: "selection")
  end

  test "the library copy exists in every supported language" do
    { es: "Biblioteca", fr: "Bibliothèque", en: "Library", "pt-BR": "Biblioteca" }.each do |locale, title|
      get scripture_library_path(preview: 1, locale:)

      assert_response :success
      assert_select ".scripture-library__hero h1", text: title
      assert_select ".scripture-library-row", count: 7
    end
  end

  private

    def sign_in_person(person, token: "library-device")
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
