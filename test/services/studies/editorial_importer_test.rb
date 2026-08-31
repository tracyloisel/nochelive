require "test_helper"

module Studies
  class EditorialImporterTest < ActiveSupport::TestCase
    setup do
      @starts_on = Date.new(2047, 8, 26)
      @program = StudyProgram.create!(
        slug: "editorial-reimport-#{SecureRandom.hex(6)}",
        title: "Programme editorial",
        year: 2047,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/editorial-reimport"
      )
      @unit = @program.study_units.create!(
        slug: "week-35",
        kind: "week",
        position: 35,
        title: "Psaumes 49-72",
        source_url: "https://example.test/manual/35",
        starts_on: @starts_on,
        ends_on: @starts_on + 6.days,
        scripture_refs: [ "Psaumes 49-72" ],
        status: "published"
      )
      @source_row = YAML.safe_load_file(
        Rails.root.join("config/study/come_follow_me_2026.yml")
      ).fetch("quizzes").first.deep_dup
      @base_content = @source_row.fetch("content")
      @base = @unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content: @base_content,
        content_digest: StudyQuizVersion.content_digest_for(@base_content),
        published_at: 2.days.ago
      )
      @discoveries = daily_discoveries
      @editorial = PublishDailyDiscoveries.call(
        study_unit: @unit,
        discoveries: @discoveries,
        expected_discoveries_digest: StudyQuizVersion.content_digest_for(@discoveries),
        at: 1.day.ago
      )
    end

    test "reimport keeps the already published daily editorial visible" do
      imported = import_rows(@source_row)

      assert_equal [ @editorial.id ], imported.map(&:id)
      assert_equal 2, @unit.study_quiz_versions.count
      assert_equal [ @editorial.id ], @unit.study_quiz_versions.where(status: "published").pluck(:id)
      assert_equal @discoveries, @unit.reload.published_quiz.daily_discoveries
      assert_equal "retired", @base.reload.status
    end

    test "a corrected source payload publishes atomically without dropping daily discoveries" do
      corrected = @source_row.deep_dup
      corrected["content"]["import_revision"] = "corrected"

      imported = import_rows(corrected).sole

      assert_equal "published", imported.status
      assert_equal "corrected", imported.content["import_revision"]
      assert_equal @discoveries, imported.daily_discoveries
      assert_equal "retired", @editorial.reload.status
      assert_equal [ imported.id ], @unit.study_quiz_versions.where(status: "published").pluck(:id)
    end

    test "repairs an earlier reimport that left a base quiz masking the daily editorial" do
      masked = @unit.study_quiz_versions.create!(
        version: 3,
        status: "published",
        editorial_locale: "fr",
        content: @base_content,
        content_digest: StudyQuizVersion.content_digest_for(@base_content),
        published_at: Time.current
      )
      assert_equal masked.id, @unit.reload.published_quiz.id
      assert_empty @unit.published_quiz.daily_discoveries

      repaired = import_rows(@source_row).sole

      assert_equal @discoveries, repaired.daily_discoveries
      assert_equal "retired", @editorial.reload.status
      assert_equal "retired", masked.reload.status
      assert_equal [ repaired.id ], @unit.study_quiz_versions.where(status: "published").pluck(:id)
    end

    test "rolls back earlier rows when the complete import cannot finish" do
      corrected = @source_row.deep_dup
      corrected["content"]["import_revision"] = "must-roll-back"
      missing = @source_row.deep_dup.merge("source_page" => "missing")

      assert_raises(ActiveRecord::RecordNotFound) { import_rows(corrected, missing) }

      assert_equal 2, @unit.study_quiz_versions.count
      assert_equal "published", @editorial.reload.status
      assert_equal [ @editorial.id ], @unit.study_quiz_versions.where(status: "published").pluck(:id)
      refute @unit.published_quiz.content.key?("import_revision")
    end

    test "can refresh one explicitly selected source page" do
      imported = Tempfile.create([ "editorial-importer", ".yml" ]) do |file|
        file.write({ "quizzes" => [ @source_row ] }.to_yaml)
        file.flush
        EditorialImporter.call(program: @program, path: file.path, source_pages: [ @source_row.fetch("source_page") ])
      end

      assert_equal [ @editorial.id ], imported.map(&:id)

      skipped = Tempfile.create([ "editorial-importer", ".yml" ]) do |file|
        file.write({ "quizzes" => [ @source_row ] }.to_yaml)
        file.flush
        EditorialImporter.call(program: @program, path: file.path, source_pages: [ "another-page" ])
      end
      assert_empty skipped
      assert_equal 2, @unit.study_quiz_versions.count
    end

    private

      def import_rows(*rows)
        Tempfile.create([ "editorial-importer", ".yml" ]) do |file|
          file.write({ "quizzes" => rows }.to_yaml)
          file.flush
          return EditorialImporter.call(program: @program, path: file.path)
        end
      end

      def daily_discoveries
        7.times.map do |index|
          localized_copy = Locale::AVAILABLE.index_with do |locale|
            {
              "eyebrow" => "#{locale} aujourd'hui",
              "title" => "#{locale} porte #{index + 1}",
              "setup" => "#{locale} une scene du psaume.",
              "question" => "#{locale} que remarques-tu ?",
              "cta_label" => "#{locale} decouvrir"
            }
          end
          localized_text = Locale::AVAILABLE.index_with { |locale| "#{locale} illustration." }

          {
            "id" => "daily-#{index + 1}",
            "kind" => index == 6 ? "contemplation" : "discovery",
            "revision" => 1,
            "scheduled_on" => (@starts_on + index.days).iso8601,
            "timezone" => "Europe/Madrid",
            "status" => "approved",
            "pack_id" => nil,
            "reference" => "ot/ps/49",
            "references" => [ "ot/ps/49" ],
            "claim_ids" => [ "claim-#{index + 1}" ],
            "depiction_mode" => "contemporary_human_scene",
            "certainty" => "ATTESTE",
            "artwork_key" => "scripture.library.daily.#{index + 1}",
            "light_family" => "celestial_dark",
            "motion" => "still",
            "audio" => "silent",
            "truth_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "experience_gate" => { "status" => "PASS", "reviewed_revision" => 1 },
            "copy" => localized_copy,
            "alt" => localized_text,
            "disclosure" => localized_text
          }
        end
      end
  end
end
