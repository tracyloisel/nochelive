require "test_helper"

class ScriptureLibrariesControllerTest < ActionDispatch::IntegrationTest
  test "the personal library is one editorial stream" do
    get scripture_library_path(preview: 1, locale: :fr)

    assert_response :success
    assert_select "body.is-scripture-library.is-celestial-dark"
    assert_select ".scripture-library__hero h1", text: "Bibliothèque"
    assert_select ".scripture-library-row", count: 7
    assert_select ".scripture-library-row.is-priority[data-library-row='resume']", count: 1
    assert_select ".scripture-library-row[data-library-row='recommendation']", text: /1 Néphi 5:1/
    assert_select ".scripture-library-row[data-library-row='weekly'] [role='progressbar'][aria-valuenow='58']"
    assert_select ".navigation-dock__item.is-active[href='#{scripture_library_path}']", text: "Bibliothèque"
  end

  test "the library copy exists in every supported language" do
    { es: "Biblioteca", fr: "Bibliothèque", en: "Library", "pt-BR": "Biblioteca" }.each do |locale, title|
      get scripture_library_path(preview: 1, locale:)

      assert_response :success
      assert_select ".scripture-library__hero h1", text: title
      assert_select ".scripture-library-row", count: 7
    end
  end

  test "the search field is present in the hero" do
    get scripture_library_path(preview: 1, locale: :fr)

    assert_response :success
    assert_select "form#recherche-ecritures[role='search']"
    assert_select "input#scripture_library_query[placeholder=?]", "DyC 48 ou Jean 3:16"
    assert_select "button.scripture-library-search__submit", text: "Ouvrir"
  end

  test "search redirects to an exact scripture passage" do
    get scripture_library_search_path(q: "matthieu 7:14", locale: :fr)

    assert_response :see_other
    assert_redirected_to "/fr/bible/matthieu/7/14"
  end

  test "search redirects for Doctrine and Covenants abbreviation" do
    get scripture_library_search_path(q: "DyC 48", locale: :fr)

    assert_response :see_other
    assert_redirected_to "/fr/doctrine-et-alliances/sections/48"
  end

  test "search renders suggestions for an ambiguous book name" do
    get scripture_library_search_path(q: "matthieu", locale: :fr)

    assert_response :success
    assert_select "#scripture-library-suggestions a", text: "Matthieu"
  end

  test "search returns unprocessable for an empty query" do
    get scripture_library_search_path(q: "", locale: :fr)

    assert_response :unprocessable_entity
    assert_select "#scripture-library-search-status", text: /Saisis un livre et un chapitre/
  end
end
