require "test_helper"

class Scriptures::QueryResolverTest < ActiveSupport::TestCase
  def resolver = Scriptures::QueryResolver

  test "resolves a full French book name with chapter and verse" do
    result = resolver.call(query: "matthieu 7:14", locale: :fr)
    assert result.exact?
    assert_equal "/fr/bible/matthieu/7/14", result.path
  end

  test "resolves a full Spanish book name with chapter" do
    result = resolver.call(query: "mateo 7", locale: :es)
    assert result.exact?
    assert_equal "/es/biblia/mateo/7", result.path
  end

  test "resolves Doctrine and Covenants abbreviations across locales" do
    {
      fr: [ "DyC 48", "/fr/doctrine-et-alliances/sections/48" ],
      es: [ "dyc 48", "/es/doctrina-y-convenios/secciones/48" ],
      en: [ "dc 48", "/en/doctrine-and-covenants/sections/48" ],
      "pt-BR": [ "dyc 48", "/pt-br/doutrina-e-convenios/secoes/48" ]
    }.each do |locale, (query, expected)|
      result = resolver.call(query:, locale:)
      assert result.exact?, "expected #{query} (#{locale}) to be exact"
      assert_equal expected, result.path
    end
  end

  test "resolves D&A as a French Doctrine and Covenants alias" do
    result = resolver.call(query: "D&A", locale: :fr)
    assert_equal :ambiguous, result.status
    assert_equal "Doctrine et Alliances", result.suggestions.first.label
  end

  test "resolves common English abbreviations" do
    {
      "gen 1" => "/en/bible/genesis/1",
      "ps 23" => "/en/bible/psalms/23",
      "john 3:16" => "/en/bible/john/3/16",
      "rev 21:4" => "/en/bible/revelation/21/4",
      "1 cor 13" => "/en/bible/1-corinthians/13"
    }.each do |query, expected|
      result = resolver.call(query:, locale: :en)
      assert result.exact?, "expected #{query} to be exact, got #{result.status}"
      assert_equal expected, result.path
    end
  end

  test "resolves compact and spaced numeric book prefixes" do
    {
      "1ne 5" => "/fr/livre-de-mormon/1-nephi/5",
      "1 ne 5" => "/fr/livre-de-mormon/1-nephi/5",
      "1nephi 5" => "/fr/livre-de-mormon/1-nephi/5",
      "1 néphi 5" => "/fr/livre-de-mormon/1-nephi/5",
      "1 cor 13" => "/fr/bible/1-corinthiens/13",
      "1cor 13" => "/fr/bible/1-corinthiens/13",
      "1 pe 2" => "/fr/bible/1-pierre/2",
      "1 jn 4" => "/fr/bible/1-jean/4",
      "2 kgs 2" => "/fr/bible/2-rois/2"
    }.each do |query, expected|
      result = resolver.call(query:, locale: :fr)
      assert result.exact?, "expected #{query} to be exact, got #{result.status} (suggestions: #{result.suggestions.map(&:label).inspect})"
      assert_equal expected, result.path
    end
  end

  test "returns ambiguous suggestions for a bare book name" do
    result = resolver.call(query: "matthieu", locale: :fr)
    assert_equal :ambiguous, result.status
    assert result.suggestions.any? { |s| s.label == "Matthieu" }
  end

  test "rejects an empty query as invalid" do
    result = resolver.call(query: "", locale: :fr)
    assert_equal :invalid, result.status
    assert_equal "scripture_library.search.errors.empty", result.message_key
  end

  test "rejects an unknown book as invalid" do
    result = resolver.call(query: "xyzzy 5", locale: :fr)
    assert_equal :invalid, result.status
    assert_equal "scripture_library.search.errors.unknown", result.message_key
  end

  test "rejects an out-of-range chapter as invalid" do
    result = resolver.call(query: "matthieu 99", locale: :fr)
    assert_equal :invalid, result.status
    assert_equal "scripture_library.search.errors.bounds", result.message_key
  end

  test "resolves a verse range" do
    result = resolver.call(query: "matthieu 7:14-20", locale: :fr)
    assert result.exact?
    assert_equal "/fr/bible/matthieu/7/14-20", result.path
  end
end
