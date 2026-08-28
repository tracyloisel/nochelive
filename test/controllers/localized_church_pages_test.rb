require "test_helper"

class LocalizedChurchPagesTest < ActionDispatch::IntegrationTest
  test "serves an indexable church page with localized canonical and alternates" do
    get localized_church_path(locale: "fr", church_section: "eglise-de-jesus-christ", church_page: "croyances")

    assert_response :success
    assert_select "html[lang=fr]"
    assert_select "title", text: /Croyances/
    assert_select "meta[name=description]", count: 1
    assert_select "link[rel=canonical][href$='/fr/eglise-de-jesus-christ/croyances']", count: 1
    assert_select "link[rel=alternate][hreflang=es]", count: 1
    assert_select "link[rel=alternate][hreflang=fr]", count: 1
    assert_select "link[rel=alternate][hreflang=en]", count: 1
    assert_select "link[rel=alternate][hreflang=pt-br]", count: 1
    assert_equal "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1", response.headers["X-Robots-Tag"].presence || css_select("meta[name=robots]").first["content"]
  end

  test "rejects a slug from another locale" do
    get localized_church_path(locale: "fr", church_section: "eglise-de-jesus-christ", church_page: "beliefs")
    assert_response :not_found
  end
end
