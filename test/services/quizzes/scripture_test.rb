require "test_helper"

class Quizzes::ScriptureTest < ActiveSupport::TestCase
  test "builds study urls for bible bom dc and pearl including joseph smith history" do
    catalog = QuizDefinition.catalog
    bible = catalog.find_question("coronas", "ungio_david")
    bom = catalog.find_question("placas", "lehi_jerusalen")
    dc = catalog.find_question("inicios", "seis_abril")
    abr = catalog.find_question("kolob", "cerca_trono")
    moses = catalog.find_question("moises", "moises_cara")
    jsh = catalog.find_question("jose", "nacio_sharon")

    I18n.with_locale(:es) do
      assert_equal "https://www.churchofjesuschrist.org/study/scriptures/ot/1-sam/16?lang=spa", Quizzes::Scripture.url(bible)
      assert_equal "https://www.churchofjesuschrist.org/study/scriptures/bofm/1-ne/2?lang=spa", Quizzes::Scripture.url(bom)
    end
    I18n.with_locale(:en) do
      assert_match %r{/dc-testament/dc/20\?lang=eng\z}, Quizzes::Scripture.url(dc)
    end
    I18n.with_locale(:fr) do
      assert_match %r{/pgp/abr/3\?lang=fra\z}, Quizzes::Scripture.url(abr)
      assert_match %r{/pgp/moses/1\?lang=fra\z}, Quizzes::Scripture.url(moses)
    end
    I18n.with_locale(:"pt-BR") do
      assert_match %r{/pgp/js-h/1\?lang=por\z}, Quizzes::Scripture.url(jsh)
    end
    assert_equal Quizzes::Scripture.url(jsh, locale: :en), Quizzes::Scripture.call(question: jsh, locale: :en)
    assert_equal Quizzes::Scripture.url(bible), Quizzes::Scripture.page_url("ot/1-sam/16")
    assert Quizzes::Scripture.known_study?("ot/1-sam/16")
    refute Quizzes::Scripture.known_study?("ot/gen/1")
  end
end
