require "test_helper"

class Studies::ProgramImporterTest < ActiveSupport::TestCase
  SOURCE_PAGES = %w[001-conversion 01 02 07-thoughts 53-appendix-a].freeze
  TITLES = {
    "fra" => [
      "Notre but est la conversion",
      "29 décembre – 4 janvier : Introduction à l’Ancien Testament",
      "5 – 11 janvier : Moïse 1 ; Abraham 3",
      "Réflexions à garder à l’esprit : L’alliance",
      "Annexe A : Pour les parents"
    ],
    "spa" => [
      "Nuestra meta es la conversión",
      "29 de diciembre–4 de enero: Introducción al Antiguo Testamento",
      "5–11 de enero: Moisés 1; Abraham 3",
      "Ideas a tener presentes: El convenio",
      "Apéndice A: Para los padres"
    ],
    "eng" => [
      "Conversion Is Our Goal",
      "December 29–January 4: Introduction to the Old Testament",
      "January 5–11: Moses 1; Abraham 3",
      "Thoughts to Keep in Mind: The Covenant",
      "Appendix A: For Parents"
    ],
    "por" => [
      "Nosso objetivo é a conversão",
      "29 de dezembro a 4 de janeiro: Introdução ao Velho Testamento",
      "5 a 11 de janeiro: Moisés 1; Abraão 3",
      "Para ponderar: O convênio",
      "Apêndice A: Para os pais"
    ]
  }.freeze

  setup do
    Studies::ProgramImporter.transport = lambda do |url|
      language = URI.decode_www_form(URI.parse(url).query).to_h.fetch("lang")
      links = SOURCE_PAGES.zip(TITLES.fetch(language)).map do |page, title|
        %(<a href="/study/manual/come-follow-me-for-home-and-church-old-testament-2026/#{page}?lang=#{language}">#{title}</a>)
      end
      "<html><body>#{links.join}</body></html>"
    end
  end
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
    second_week = first.program.study_units.weeks.second
    assert_equal [ "Moïse 1 ; Abraham 3" ], second_week.scripture_refs
    assert_equal %w[en es fr pt-BR], second_week.copy.keys.sort
    assert_equal "5–11 de enero: Moisés 1; Abraham 3", second_week.display_title(:es)
    assert_equal [ "Moses 1; Abraham 3" ], second_week.display_scripture_refs(:en)
    assert_equal "Vem, e Segue-Me — Velho Testamento 2026", first.program.display_title(:"pt-BR")
    assert_equal "fra", URI.parse(first.program.source_url).query.split("=").last
  end
end
