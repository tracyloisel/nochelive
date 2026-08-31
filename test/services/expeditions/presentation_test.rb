require "test_helper"

module Expeditions
  class PresentationTest < ActiveSupport::TestCase
    test "projects shared permanent progress without inheriting full-path locks" do
      program = StudyProgram.create!(
        slug: "presentation-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
        canon: "old_testament", locale: "fr", status: "published", source_url: "https://example.test/programme"
      )
      week = program.study_units.create!(
        slug: "week", kind: "week", position: 1, title: "Psaumes", source_url: "https://example.test/week",
        starts_on: Date.current.beginning_of_week, ends_on: Date.current.end_of_week,
        scripture_refs: [ "Psaumes" ], status: "published"
      )
      content = {
        "questions" => [], "readings" => [],
        "expedition" => {
          "id" => "six-doors", "title" => { "fr" => "Six portes" },
          "promise" => { "fr" => "Entre dans leur histoire." },
          "pack_ids" => [ "exp_psalms_disappearing_voice", "exp_psalms_nameless_king" ],
          "packs" => [ { "id" => "exp_psalms_nameless_king", "title" => { "fr" => "Le Roi sans nom" } } ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )
      digest = GameSession.digest_token("expedition-presentation")
      QuizRun.create!(
        device_digest: digest, pack_id: "exp_psalms_disappearing_voice", position: 10,
        score: 75, status: "finished", opened_at: Time.current
      )
      world = Quizzes::World.call(device_digest: digest)

      result = Presentation.call(quiz:, world:, locale: :fr)

      assert_equal "Six portes", result.title
      assert_equal 2, result.total_count
      assert_equal 1, result.completed_count
      assert_equal 50, result.progress_percent
      assert_equal 7, result.duration_days
      assert_operator result.days_remaining, :>, 0
      assert_equal :finished, result.packs.first.state
      assert_equal :available, result.packs.second.state
      assert_equal "Le Roi sans nom", result.packs.second.title
    end

    test "uses the active locale when saved expedition metadata only has French copy" do
      program = StudyProgram.create!(
        slug: "presentation-locale-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
        canon: "old_testament", locale: "fr", status: "published", source_url: "https://example.test/programme"
      )
      week = program.study_units.create!(
        slug: "week", kind: "week", position: 1, title: "Psaumes", source_url: "https://example.test/week",
        starts_on: Date.current.beginning_of_week, ends_on: Date.current.end_of_week,
        scripture_refs: [ "Psaumes" ], status: "published"
      )
      content = {
        "questions" => [], "readings" => [],
        "expedition" => {
          "id" => "six-doors", "title" => { "es" => "Seis puertas" },
          "pack_ids" => [ "exp_psalms_nameless_king" ],
          "packs" => [ { "id" => "exp_psalms_nameless_king", "title" => { "fr" => "Le Roi sans nom" } } ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )

      result = Presentation.call(quiz:, locale: :es)

      assert_equal "El Rey sin nombre", result.packs.first.title
      assert_equal "Salmo 110", result.packs.first.kicker
      assert_equal "Un rey recibe una promesa extraña: sacerdote para siempre.", result.packs.first.lede
    end
  end
end
