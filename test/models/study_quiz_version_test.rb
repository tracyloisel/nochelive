require "test_helper"

class StudyQuizVersionTest < ActiveSupport::TestCase
  setup do
    program = StudyProgram.create!(
      slug: "expedition-version-#{SecureRandom.hex(6)}",
      title: "Programme d’expédition",
      year: 2041,
      canon: "old_testament",
      locale: "fr",
      status: "published",
      source_url: "https://example.test/expedition"
    )
    @unit = program.study_units.create!(
      slug: "week-1",
      kind: "week",
      position: 1,
      title: "Psaumes",
      source_url: "https://example.test/expedition/week",
      starts_on: Date.current.beginning_of_week,
      ends_on: Date.current.end_of_week,
      scripture_refs: [ "Psaumes" ],
      status: "published"
    )
  end

  test "an expedition is only a list of permanent pack ids" do
    content = expedition_content
    quiz = @unit.study_quiz_versions.create!(
      version: 1,
      status: "published",
      editorial_locale: "fr",
      content:,
      content_digest: Digest::SHA256.hexdigest(content.to_json),
      published_at: Time.current
    )

    assert quiz.expedition?
    assert_empty quiz.questions
    assert_equal [ "exp_psalms_disappearing_voice", "exp_psalms_nameless_king" ], quiz.expedition_pack_ids
  end

  test "an expedition rejects duplicated embedded questions and unknown packs" do
    duplicated = expedition_content.merge("questions" => [ { "id" => "copy" } ])
    quiz = @unit.study_quiz_versions.build(
      version: 1, status: "draft", editorial_locale: "fr", content: duplicated,
      content_digest: "duplicate"
    )
    refute quiz.valid?
    assert_includes quiz.errors[:content], "expedition cannot embed a second quiz set"

    unknown = expedition_content.deep_dup
    unknown["expedition"]["pack_ids"] << "invented-pack"
    quiz.content = unknown
    quiz.content_digest = "unknown"
    refute quiz.valid?
    assert quiz.errors[:content].any? { |error| error.include?("invented-pack") }
  end

  test "does not use French reading labels as a cross-locale fallback" do
    quiz = StudyQuizVersion.new(content: {
      "readings" => [ { "study" => "ot/ps/102", "labels" => { "fr" => "Psaume 102" } } ]
    })

    assert_nil quiz.readings(:es).first.fetch("label")
  end

  test "uses a canonical digest for reviewed daily discovery content" do
    first = { "daily_discoveries" => [ { "id" => "daily-01", "copy" => { "fr" => "Texte" } } ], "questions" => [] }
    reordered = { "questions" => [], "daily_discoveries" => [ { "copy" => { "fr" => "Texte" }, "id" => "daily-01" } ] }

    assert_equal StudyQuizVersion.content_digest_for(first), StudyQuizVersion.content_digest_for(reordered)
  end

  private

    def expedition_content
      {
        "questions" => [],
        "readings" => [],
        "expedition" => {
          "id" => "weekly-psalms",
          "title" => { "fr" => "Six portes" },
          "pack_ids" => [ "exp_psalms_disappearing_voice", "exp_psalms_nameless_king" ]
        }
      }
    end
end
