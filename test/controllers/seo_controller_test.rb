require "test_helper"

class SeoControllerTest < ActionDispatch::IntegrationTest
  test "lists discovery clusters and scripture pages with localized alternates" do
    get sitemap_path(format: :xml)

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_select "urlset url", minimum: 5_000
    assert_includes response.body, "/es/juegos-biblicos"
    assert_includes response.body, "/es/actividades-cristianas"
    assert_includes response.body, "/es/estudio-biblico"
    assert_includes response.body, "/fr/bible/2-samuel/2/1"
    assert_includes response.body, "/fr/bible/2-samuel"
    assert_includes response.body, "/fr/bible/2-samuel/2"
    assert_includes response.body, "/es/biblia/apocalipsis/22"
    assert_includes response.body, "/es/biblia/2-samuel/2/1"
    assert_includes response.body, "/pt-br/biblia/2-samuel/2/1"
    assert_includes response.body, "/en/bible/2-samuel/2/1"
    assert_includes response.body, "/fr/bible/1-rois/21/2-3"
    assert_includes response.body, "/es/biblia/1-reyes/21/2-3"
    assert_includes response.body, "/es/santos-de-los-ultimos-dias/benidorm"
    assert_includes response.body, "/fr/saints-des-derniers-jours/benidorm"
    assert_includes response.body, "/en/latter-day-saints/benidorm"
    assert_includes response.body, "/pt-br/santos-dos-ultimos-dias/benidorm"
    assert_includes response.body, "/fr/livre-de-mormon/moroni/10"
    assert_includes response.body, "/en/doctrine-and-covenants/sections/121"
    assert_includes response.body, "/fr/eglise-de-jesus-christ/croyances"
    assert_select "loc", text: %r{/fr/jeux-bibliques}, minimum: 1
    assert_select "loc", text: %r{/en/bible-games}, minimum: 1
    assert_select "loc", text: %r{/pt-br/jogos-biblicos}, minimum: 1
    assert_select "xhtml|link[rel=alternate][hreflang=fr]", minimum: 5_000
    assert_select "xhtml|link[rel=alternate][hreflang=x-default]", minimum: 5_000
    refute_includes response.body, "https://localhost"
    assert_includes response.body, "http://www.example.com"
    refute_includes response.body, "/ficha"
    refute_includes response.body, "/jugadores/"
    locations = Nokogiri::XML(response.body).xpath("//*[local-name()='loc']").map(&:text)
    assert_equal locations.uniq, locations
  end

  test "robots excludes profile gates and explicit player pages" do
    robots = Rails.root.join("public/robots.txt").read

    assert_equal 3, robots.scan(/^Disallow: \/ficha$/).size
    assert_equal 3, robots.scan(%r{^Disallow: /jugadores/$}).size
  end
end
