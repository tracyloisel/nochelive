require "test_helper"

class AgentDiscoveryControllerTest < ActionDispatch::IntegrationTest
  test "publishes a concise multilingual agent index" do
    get llms_path

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "# Noche Live"
    assert_includes response.body, "## Español"
    assert_includes response.body, "## Français"
    assert_includes response.body, "http://www.example.com/agent/fr/jeux-bibliques.md"
    assert_includes response.body, "http://www.example.com/sitemap.xml"
    refute_includes response.body, "http://www.example.com/p/"
    refute_includes response.body, "http://www.example.com/s/"
    assert_match(/public/, response.headers["Cache-Control"])
    assert_equal "noindex, follow", response.headers["X-Robots-Tag"]
  end

  test "renders every localized public page as markdown" do
    Seo::DiscoveryPage.all.each do |key|
      I18n.available_locales.each do |locale|
        options = Seo::DiscoveryPage.path_options(key, locale)
        page = Seo::DiscoveryPage.resolve(locale: options[:locale], slug: options[:slug])

        get Ai::SiteCatalog.markdown_path(page)

        assert_response :success, "expected #{key} in #{locale}"
        assert_equal "text/markdown", response.media_type
        assert_equal options[:locale], response.headers["Content-Language"]
        assert_includes response.body, "# #{I18n.with_locale(locale) { I18n.t("seo.discovery.pages.#{key}.h1") }}"
        assert_includes response.headers["Link"], "rel=\"canonical\""
        assert_includes response.headers["Link"], "rel=\"describedby\""
      end
    end
  end

  test "does not turn unknown paths into agent-readable content" do
    get "/agent/fr/espace-prive.md"

    assert_response :not_found
  end
end
