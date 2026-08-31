require "test_helper"

class ScriptureLibrariesControllerTest < ActionDispatch::IntegrationTest
  test "preview opens on one daily discovery and the editorial stream" do
    get scripture_library_path(preview: 1, locale: :fr)

    assert_response :success
    assert_select "body.is-scripture-library.is-celestial-dark"
    assert_select "head link[rel='stylesheet'][href*='surfaces/library']", count: 1
    assert_select ".scripture-library-daily[data-daily-discovery-id='preview-ps137-suspended-harps']", count: 1
    assert_select ".scripture-library-daily h1", text: "Ils ont refusé de chanter."
    assert_select ".scripture-library-daily__world picture img[alt*='lyre suspendue']", count: 1
    assert_select ".scripture-library-action--hero[href^='/escrituras/ot/ps/137'][href*='locale=fr']", count: 1
    assert_select "form#recherche-ecritures[action='#{scripture_library_search_path}'][method=get]"
    assert_select "input[role=combobox][aria-controls=scripture-library-suggestions]"
    assert_select ".scripture-library-resume", text: /Psaumes 119/
    assert_select ".scripture-library-week .scripture-library-row[data-library-row='weekly']", count: 1 do
      assert_select "#expedition", count: 1
      assert_select "[role='progressbar'][aria-valuenow='58']", count: 1
      assert_select "[role='progressbar'][aria-valuenow='33']", count: 1
    end
    assert_select ".scripture-library-quiz", text: /Melchisédek/
    assert_select ".scripture-library-rama__thought", count: 2
    assert_select ".scripture-library-tools .scripture-library-row", count: 3
    assert_select ".scripture-library-row[data-library-row='expedition']", count: 0
    assert_select ".navigation-dock__item.is-active[href='#{scripture_library_path}']", text: "Bibliothèque"
  end

  test "a visitor never receives fabricated resume quiz bookmarks or rama content" do
    get scripture_library_path(locale: :fr)

    assert_response :success
    assert_select ".scripture-library-resume", count: 0
    assert_select ".scripture-library-quiz", count: 0
    assert_select ".scripture-library-rama", count: 0
    assert_select ".scripture-library-row[data-library-row='bookmarks']", count: 0
    assert_select ".scripture-library-row[data-library-row='collection'][href*='section=canon'][href*='locale=fr']", count: 1
    assert_not_includes response.body, I18n.t("scripture_library.resume.empty_detail", locale: :fr)
    assert_not_includes response.body, I18n.t("scripture_library.rama.unavailable", locale: :fr)
  end

  test "the daily opening and stream labels stay native in every supported language" do
    {
      es: [ "Se negaron a cantar.", "Retomar", "Hoy en tu rama" ],
      fr: [ "Ils ont refusé de chanter.", "Reprendre", "Aujourd’hui dans ta rama" ],
      en: [ "They refused to sing.", "Resume", "Today in your ward" ],
      "pt-BR": [ "Eles se recusaram a cantar.", "Retomar", "Hoje na sua ala" ]
    }.each do |locale, (title, resume_label, rama_label)|
      get scripture_library_path(preview: 1, locale:)

      assert_response :success
      assert_select ".scripture-library-daily h1", text: title
      assert_select ".scripture-library-resume .scripture-library-kicker", text: /#{Regexp.escape(resume_label)}/
      assert_select ".scripture-library-rama .scripture-library-kicker", text: /#{Regexp.escape(rama_label)}/
      assert_not_includes response.body, "translation missing"
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
    assert_select ".scripture-library-resume__link[href^='/escrituras/ot/1-sam/16'][href*='locale=fr']", count: 1
    assert_select ".scripture-library-row[data-library-row='bookmarks'][href*='section=bookmarks']", count: 1
    assert_select ".scripture-library-rama", count: 0

    get scripture_library_path(locale: :fr, section: "bookmarks", anchor: "selection")
    assert_response :success
    assert_select ".scripture-library-row[data-library-row='bookmarks'][aria-current='true']", count: 1
    assert_select "turbo-frame#library_selection", count: 1 do
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
      assert_select ".scripture-library-row[data-library-row='#{row}'][aria-current='true']", count: 1
      assert_select "turbo-frame#library_selection", count: 1 do
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
    assert_select ".scripture-library-row[data-library-row='collection'][aria-current='true']", count: 1
    assert_select "turbo-frame#library_selection", count: 1 do
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
    assert_select ".scripture-library-row[data-library-row='collection'][aria-current='true']", count: 1
    assert_select "turbo-frame#library_selection .scripture-library-selection", count: 1

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

  test "the editorial library copy exists in every supported language" do
    {
      es: "Se negaron a cantar.",
      fr: "Ils ont refusé de chanter.",
      en: "They refused to sing.",
      "pt-BR": "Eles se recusaram a cantar."
    }.each do |locale, title|
      get scripture_library_path(preview: 1, locale:)

      assert_response :success
      assert_select ".scripture-library-daily h1", text: title
      assert_select ".scripture-library-action--hero", count: 1
      assert_select ".scripture-library-week", count: 1
      assert_select ".scripture-library-tools", count: 1
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
