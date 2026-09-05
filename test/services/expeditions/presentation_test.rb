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
          "pack_ids" => [ "psalms_living_god", "psalms_servant_king" ],
          "packs" => [ { "id" => "psalms_servant_king", "title" => { "fr" => "Le Roi sans nom" } } ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )
      digest = GameSession.digest_token("expedition-presentation")
      QuizRun.create!(
        device_digest: digest, pack_id: "psalms_living_god", position: 10,
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
      assert_equal "Voici Jésus-Christ", result.packs.second.title
      assert_nil result.rama_headline
      assert_nil result.rama_artwork_key
      assert_nil result.rama_light_family
    end

    test "projects an arbitrary Council Rama hero without inferring it from Psalms" do
      headlines = {
        "es" => "Una pequeña llama puede cambiar toda una casa.",
        "pt-BR" => "Uma pequena chama pode mudar uma casa inteira.",
        "fr" => "Une petite flamme peut changer toute une maison.",
        "en" => "A small flame can change an entire home."
      }
      program = StudyProgram.create!(
        slug: "presentation-rama-hero-#{SecureRandom.hex(6)}", title: "Programme", year: 2042,
        canon: "old_testament", locale: "es", status: "published", source_url: "https://example.test/programme"
      )
      week = program.study_units.create!(
        slug: "week", kind: "week", position: 1, title: "Salmos", source_url: "https://example.test/week",
        starts_on: Date.current.beginning_of_week, ends_on: Date.current.end_of_week,
        scripture_refs: %w[ot/ps/102 ot/ps/110], status: "published"
      )
      content = {
        "questions" => [], "readings" => [],
        "expedition" => {
          "id" => "council-owned-rama-hero",
          "title" => Locale::AVAILABLE.index_with { |locale| "Expedition #{locale}" },
          "pack_ids" => [ "psalms_servant_king" ],
          "packs" => [ { "id" => "psalms_servant_king" } ],
          "rama_hero" => {
            "revision" => 1,
            "headline" => headlines,
            "artwork_key" => "expedition.psalms-102-150-fast.rama-weekly-hero",
            "artwork_digest" => RamaHero.artwork_digest_for("expedition.psalms-102-150-fast.rama-weekly-hero"),
            "light_family" => "celestial_light"
          }
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "es", content:,
        content_digest: StudyQuizVersion.content_digest_for(content), published_at: Time.current
      )

      Locale::AVAILABLE.each do |locale|
        result = Presentation.call(quiz:, locale:)

        assert_equal headlines.fetch(locale), result.rama_headline
        assert_equal "expedition.psalms-102-150-fast.rama-weekly-hero", result.rama_artwork_key
        assert_equal "celestial_light", result.rama_light_family
      end

      # General presentation still normalizes unsupported locales for its
      # legacy copy, but the Rama projection itself must never do that.
      assert_nil Presentation.call(quiz:, locale: :de).rama_headline
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
          "pack_ids" => [ "psalms_servant_king" ],
          "packs" => [ { "id" => "psalms_servant_king", "title" => { "fr" => "Le Roi sans nom" } } ]
        }
      }
      quiz = week.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json), published_at: Time.current
      )

      result = Presentation.call(quiz:, locale: :es)

      assert_equal "Este es Jesucristo", result.packs.first.title
      assert_equal "Salmos 110 · 118", result.packs.first.kicker
      assert_equal "Un sacerdote para siempre. Una piedra rechazada que llega a ser la principal. El Nuevo Testamento ayuda a los cristianos a reconocer a Jesucristo en estas imágenes de los Salmos 110 y 118.", result.packs.first.lede
    end

    test "uses exact-locale public presentation copy for every Psalms door" do
      pack_ids = %w[
        psalms_living_god
        psalms_servant_king
        psalms_hears_knows
        psalms_walk_with_god
        psalms_build_home
        psalms_every_breath
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
          # Persisted metadata intentionally has no localized title: the
          # canonical four-locale FAST catalog owns title, kicker and lede.
          "packs" => pack_ids.map { |pack_id| { "id" => pack_id } }
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
          definition = QuizDefinition.catalog.find_pack(pack.id)
          %w[title kicker lede].each do |field|
            expected = I18n.with_locale(locale) { definition.copy(field) }
            assert_equal expected, pack.public_send(field), "#{pack.id}.#{field} leaked in #{locale}"
          end
          assert_nil pack.hook
          refute_equal I18n.with_locale(:es) { definition.copy(:title) }, pack.title unless locale == "es"
        end
      end
    end

    test "omits an expedition rather than borrowing another locale for its headline" do
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

      assert_nil Presentation.call(quiz:, locale: :fr)
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
          "pack_ids" => [ "psalms_servant_king" ],
          "packs" => [ { "id" => "psalms_servant_king" } ]
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
