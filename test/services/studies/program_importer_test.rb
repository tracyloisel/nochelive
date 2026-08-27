require "test_helper"

class Studies::ProgramImporterTest < ActiveSupport::TestCase
  HTML = <<~HTML
    <html><body><h1>Viens et suis-moi — Ancien Testament 2026</h1>
      <a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/001-conversion?lang=fra">Notre but est la conversion</a>
      <a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/01?lang=fra">29&nbsp;décembre&nbsp;–&nbsp;4&nbsp;janvier&nbsp;: Introduction à l’Ancien Testament</a>
      <a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/02?lang=fra">5&nbsp;–&nbsp;11&nbsp;janvier&nbsp;: Moïse 1 ; Abraham 3</a>
      <a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/07-thoughts?lang=fra">Réflexions à garder à l’esprit : L’alliance</a>
      <a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/53-appendix-a?lang=fra">Annexe A : Pour les parents</a>
    </body></html>
  HTML

  setup { Studies::ProgramImporter.transport = ->(_url) { HTML } }
  teardown { Studies::ProgramImporter.transport = nil }

  test "imports weeks and permanent resources idempotently" do
    url = "https://www.churchofjesuschrist.org/study/manual/come-follow-me-for-home-and-church-old-testament-2026/000-contents?lang=fra."
    first = Studies::ProgramImporter.call(url:)
    second = Studies::ProgramImporter.call(url:)

    assert_equal 5, first.created
    assert_equal 5, second.unchanged
    assert_equal 2, first.program.study_units.weeks.count
    assert_equal 1, first.program.study_units.appendices.count
    assert_equal Date.new(2025, 12, 29), first.program.study_units.weeks.first.starts_on
    assert_equal [ "Moïse 1 ; Abraham 3" ], first.program.study_units.weeks.second.scripture_refs
    assert_equal "fra", URI.parse(first.program.source_url).query.split("=").last
  end
end
