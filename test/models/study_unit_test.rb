require "test_helper"

class StudyUnitTest < ActiveSupport::TestCase
  setup do
    @program = StudyProgram.create!(
      slug: "come-follow-me-localization-test", title: "Viens et suis-moi — Ancien Testament 2037",
      year: 2037, canon: "old_testament", locale: "fr", status: "published",
      source_url: "https://example.test/program"
    )
    @unit = @program.study_units.create!(
      slug: "week-36", kind: "week", position: 36,
      title: "31 août – 6 septembre : Psaumes 102-103 ; 110 ; 116-119",
      starts_on: Date.new(2037, 8, 31), ends_on: Date.new(2037, 9, 6),
      scripture_refs: [ "Psaumes 102-103 ; 110 ; 116-119" ],
      source_url: "https://example.test/week-36", status: "published"
    )
  end

  test "localizes an existing French annual program without waiting for a reimport" do
    assert_equal "Ven, sígueme — Antiguo Testamento 2037", @program.display_title(:es)
    assert_equal "31 de agosto–6 de septiembre: Salmos 102-103; 110; 116-119", @unit.display_title(:es)
    assert_equal "August 31–September 6: Psalms 102-103; 110; 116-119", @unit.display_title(:en)
    assert_equal "31 de agosto–6 de setembro: Salmos 102-103; 110; 116-119", @unit.display_title(:"pt-BR")
    assert_equal [ "Salmos 102-103; 110; 116-119" ], @unit.display_scripture_refs(:es)
  end

  test "prefers the official localized title saved by the importer" do
    @unit.update!(copy: {
      "es" => {
        "title" => "31 de agosto–6 de septiembre: Los Salmos 102–103",
        "scripture_refs" => [ "Los Salmos 102–103" ]
      }
    })

    assert_equal "31 de agosto–6 de septiembre: Los Salmos 102–103", @unit.display_title(:es)
    assert_equal "Los Salmos 102–103", @unit.display_heading(:es)
    assert_equal [ "Los Salmos 102–103" ], @unit.display_scripture_refs(:es)
  end
end
