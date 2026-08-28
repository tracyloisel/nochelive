require "test_helper"

class Scriptures::ReferenceTest < ActiveSupport::TestCase
  test "resolves the public 2 Samuel reference in every locale" do
    { "es" => "biblia", "fr" => "bible", "en" => "bible", "pt-br" => "biblia" }.each do |locale, section|
      reference = Scriptures::Reference.resolve(
        locale:, section:, book: "2-samuel", chapter: "2", verse: "1"
      )

      assert reference
      assert_equal "ot/2-sam/2", reference.study
      assert_equal "2 Samuel 2:1", reference.citation
    end
  end

  test "rejects a mismatched language section and impossible chapter" do
    assert_nil Scriptures::Reference.resolve(locale: "fr", section: "biblia", book: "2-samuel", chapter: "2", verse: "1")
    assert_nil Scriptures::Reference.resolve(locale: "fr", section: "bible", book: "2-samuel", chapter: "25", verse: "1")
  end

  test "localizes Bible book slugs while preserving the source study" do
    spanish = Scriptures::Reference.resolve(locale: "es", section: "biblia", book: "1-reyes", chapter: 3, verse: 16)

    assert_equal "ot/1-kgs/3", spanish.study
    assert_equal "1 Reyes 3:16", spanish.citation
    assert_equal "1-rois", Scriptures::Reference.path_options(spanish, :fr)[:book]
    assert_equal "1-kings", Scriptures::Reference.path_options(spanish, :en)[:book]
    assert_equal "1-reis", Scriptures::Reference.path_options(spanish, :"pt-BR")[:book]
  end

  test "publishes the Bible references already used by the game" do
    references = Scriptures::Reference.indexable_references

    assert_operator references.size, :>=, 60
    assert references.any? { |reference| reference.citation == "2 Samuel 2:1" }
    assert references.any? { |reference| reference.citation == "Juan 20:16" }
  end


  test "covers the complete standard works requested for public SEO" do
    bible = Scriptures::Reference::BOOKS.values.select { |book| book[:corpus] == :bible }
    book_of_mormon = Scriptures::Reference::BOOKS.values.select { |book| book[:corpus] == :book_of_mormon }
    doctrine = Scriptures::Reference::BOOKS.values.select { |book| book[:corpus] == :doctrine_and_covenants }

    assert_equal 66, bible.size
    assert_equal 1_189, bible.sum { |book| book[:chapters] }
    assert_equal 15, book_of_mormon.size
    assert_equal 239, book_of_mormon.sum { |book| book[:chapters] }
    assert_equal 138, doctrine.sum { |book| book[:chapters] }

    moroni = Scriptures::Reference.resolve(locale: "fr", section: "livre-de-mormon", book: "moroni", chapter: 10, verse: 4)
    dc = Scriptures::Reference.resolve(locale: "fr", section: "doctrine-et-alliances", book: "sections", chapter: 121, verse: 7)
    assert_equal "bofm/moro/10", moroni.study
    assert_equal "dc-testament/dc/121", dc.study
  end
end
