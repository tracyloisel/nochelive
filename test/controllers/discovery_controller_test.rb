require "test_helper"

class DiscoveryControllerTest < ActionDispatch::IntegrationTest
  test "renders an indexable French Bible games landing page" do
    get discovery_path(locale: "fr", slug: "jeux-bibliques")

    assert_response :success
    assert_select "html[lang=fr]"
    assert_select "title", text: /Jeux bibliques/
    assert_select "meta[name=robots][content^='index, follow']", count: 1
    assert_select "meta[name=description]", count: 1
    assert_select "link[rel=canonical][href$='/fr/jeux-bibliques']", count: 1
    assert_select "link[rel=alternate][hreflang=es]", count: 1
    assert_select "link[rel=alternate][hreflang=fr]", count: 1
    assert_select "link[rel=alternate][hreflang=en]", count: 1
    assert_select "link[rel=alternate][hreflang=pt-br]", count: 1
    assert_select "link[rel=alternate][hreflang=x-default]", count: 1
    assert_select "script[type='application/ld+json']", count: 1
    assert_select "h1", text: /regarder, rire et se souvenir/
    assert_select ".discovery-chapter", count: 3
    assert_includes response.headers["Link"], "</agent/fr/jeux-bibliques.md>; rel=\"alternate\"; type=\"text/markdown\""
    assert_includes response.headers["Link"], "</llms.txt>; rel=\"describedby\"; type=\"text/plain\""
  end

  test "uses native localized slugs for every cluster" do
    {
      "/es/juegos-biblicos/trivia-biblica" => "es",
      "/fr/activites-chretiennes/jeunes" => "fr",
      "/en/bible-study/psalms" => "en",
      "/pt-br/estudo-biblico" => "pt-BR"
    }.each do |path, locale|
      get path
      assert_response :success
      assert_select "html[lang='#{locale}']"
      assert_select "meta[name=robots][content^='index, follow']"
    end
  end

  test "renders all twenty-eight localized acquisition pages" do
    Seo::DiscoveryPage.all.each do |key|
      I18n.available_locales.each do |locale|
        options = Seo::DiscoveryPage.path_options(key, locale)
        get(options[:slug].present? ? discovery_path(**options) : discovery_home_path(locale: options[:locale]))

        assert_response :success, "expected #{key} in #{locale}"
        assert_select "meta[name=robots][content^='index, follow']", count: 1
        assert_select "h1", count: 1
        assert_select ".discovery-chapter", count: 3
      end
    end
  end

  test "returns not found for an invented SEO page" do
    get "/fr/page-inventee"
    assert_response :not_found
  end

  test "keeps the personalized application out of the index" do
    get root_path

    assert_response :success
    assert_select "meta[name=robots][content='noindex, follow']", count: 1
    assert_equal "noindex, follow", response.headers["X-Robots-Tag"]
  end
end
