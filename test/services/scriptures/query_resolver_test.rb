require "test_helper"

class Scriptures::QueryResolverTest < ActiveSupport::TestCase
  test "resolves doctrine aliases in every locale directly into the reader" do
    { fr: "Doctrine et Alliances 48", es: "Doctrina y Convenios 48",
      en: "Doctrine and Covenants 48", "pt-BR": "Doutrina e Convênios 48" }.each do |locale, citation|
      [ "DyC 48", "D&A 48", "D&C 48", "Doctrine et Alliances 48" ].each do |query|
        result = Scriptures::QueryResolver.call(query:, locale:, context: :library)
        assert result.exact?, "#{query} should resolve for #{locale}"
        assert_equal reader_path("dc-testament/dc/48", citation:, locale:), result.path
      end
    end
  end

  test "resolves localized chapters verses and ranges directly into the reader" do
    assert_equal reader_path("nt/john/3", citation: "Jean 3", locale: :fr), resolve("Jean 3", :fr).path
    assert_equal reader_path("nt/john/3", citation: "Jean 3:16", locale: :fr), resolve("Jean 3:16", :fr).path
    assert_equal reader_path("nt/john/3", citation: "Jean 3:16–17", locale: :fr), resolve("  JEÁN   3:16–17 ", :fr).path
    assert_equal reader_path("bofm/1-ne/5", citation: "1 Néfi 5", locale: :"pt-BR"), resolve("1 Néphi 5", :"pt-BR").path
  end

  test "a book search stays in the library and opens its chapter chooser" do
    result = resolve("Psaumes", :fr)

    assert result.exact?
    uri = URI.parse(result.path)
    params = Rack::Utils.parse_nested_query(uri.query)
    assert_equal Rails.application.routes.url_helpers.scripture_library_path, uri.path
    assert_equal "selection", uri.fragment
    assert_equal "canon", params["section"]
    assert_equal "old_testament", params["collection"]
    assert_equal "ot/ps", params["book"]
  end

  test "never guesses invalid or incomplete references" do
    assert_equal :ambiguous, resolve("Néphi", :fr).status
    assert_equal :invalid, resolve("Jean 99", :fr).status
    assert_equal :invalid, resolve("Jean 3:19-17", :fr).status
    assert_equal :invalid, resolve("Livre inconnu 3", :fr).status
  end

  test "validates passages against the verses actually present in the chapter" do
    assert resolve("Jean 3:36", :fr).exact?

    [ "Jean 3:37", "Jean 3:99", "Jean 3:16-99" ].each do |query|
      result = resolve(query, :fr)

      assert result.invalid?, query
      assert_equal "scripture_library.search.errors.bounds", result.message_key
    end
  end

  test "has an exact chapter bound for every searchable book" do
    Scriptures::Reference::BOOKS.each do |study, book|
      counts = Scriptures::ChapterVerseCounts::COUNTS.fetch(study)

      assert_equal book.fetch(:chapters), counts.length, study
      assert counts.all?(&:positive?), study
    end
  end

  private

    def resolve(query, locale)
      Scriptures::QueryResolver.call(query:, locale:, context: :library)
    end

    def reader_path(study, citation:, locale:)
      Rails.application.routes.url_helpers.scripture_path(study, cite: citation, locale: locale)
    end
end
