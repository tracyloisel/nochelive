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

      assert_equal "El rey sin nombre", result.packs.first.title
      assert_equal "Salmo 110", result.packs.first.kicker
      assert_equal "Un rey recibe una promesa extraña: sacerdote para siempre.", result.packs.first.lede
    end

    test "uses exact-locale public presentation copy for every Psalms door" do
      pack_ids = %w[
        exp_psalms_disappearing_voice
        exp_psalms_nameless_king
        exp_psalms_cry_stone_seek
        exp_psalms_house_table_city
        exp_psalms_suspended_harps
        exp_psalms_everything_breathes
      ]
      program = StudyProgram.create!(
        slug: "presentation-public-copy-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
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
          "id" => "six-doors",
          "title" => Locale::AVAILABLE.index_with { |locale| "Expedition #{locale}" },
          "promise" => Locale::AVAILABLE.index_with { |locale| "Promise #{locale}" },
          "pack_ids" => pack_ids,
          # This mirrors the production defect: persisted metadata offers only
          # Spanish. Presentation must never let the global fallback leak it
          # into another locale.
          "packs" => pack_ids.map do |pack_id|
            { "id" => pack_id }.merge(
              %w[title kicker lede hook].index_with do |field|
                {
                  "es" => I18n.t(
                    "expedition_pack_presentations.#{pack_id}.#{field}",
                    locale: :es, fallback: false
                  )
                }
              end
            )
          end
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )

      Locale::AVAILABLE.each do |locale|
        result = Presentation.call(quiz:, locale:)

        assert result, "expected the expedition in #{locale}"
        assert_equal pack_ids, result.pack_ids
        result.packs.each do |pack|
          %w[title kicker lede hook].each do |field|
            expected = I18n.t(
              "expedition_pack_presentations.#{pack.id}.#{field}",
              locale:, fallback: false
            )
            assert_equal expected, pack.public_send(field), "#{pack.id}.#{field} leaked in #{locale}"
          end
          refute_equal I18n.t(
            "expedition_pack_presentations.#{pack.id}.title",
            locale: :es, fallback: false
          ), pack.title unless locale == "es"
        end
      end
    end

    test "omits an expedition rather than borrowing Spanish for an untranslated door" do
      program = StudyProgram.create!(
        slug: "presentation-fail-closed-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
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
          "id" => "untranslated-door",
          "title" => { "en" => "An expedition" },
          "pack_ids" => [ "coronas" ],
          "packs" => [
            {
              "id" => "coronas",
              "title" => { "es" => "Reyes de Israel" },
              "kicker" => { "es" => "Una corona" },
              "lede" => { "es" => "Una historia" }
            }
          ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )

      assert_nil Presentation.call(quiz:, locale: :en)
    end

    test "omits an expedition rather than borrowing another locale for its heading" do
      program = StudyProgram.create!(
        slug: "presentation-heading-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
        canon: "old_testament", locale: "es", status: "published", source_url: "https://example.test/programme"
      )
      week = program.study_units.create!(
        slug: "week", kind: "week", position: 1, title: "Salmos", source_url: "https://example.test/week",
        starts_on: Date.current.beginning_of_week, ends_on: Date.current.end_of_week,
        scripture_refs: [ "Salmos" ], status: "published"
      )
      content = {
        "questions" => [], "readings" => [],
        "expedition" => {
          "id" => "untranslated-heading",
          "title" => { "es" => "Una expedición" },
          "pack_ids" => [ "exp_psalms_nameless_king" ],
          "packs" => [ { "id" => "exp_psalms_nameless_king" } ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "es", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )

      assert_nil Presentation.call(quiz:, locale: :en)
    end
  end
end
