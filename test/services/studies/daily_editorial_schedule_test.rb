require "test_helper"
require "tempfile"

module Studies
  class DailyEditorialScheduleTest < ActiveSupport::TestCase
    CONFIG_PATH = Rails.root.join("config/study/library_daily_editorials/2026-09-07-prov1-3-4-15-16-22-31-eccl1-3-12.yml")
    FAST_CONFIG_PATH = Rails.root.join("config/study/library_daily_editorials/2026-08-31-psalms-102-150.yml")

    setup do
      @data = YAML.safe_load_file(CONFIG_PATH, aliases: false)
    end

    test "accepts the canonical Council-reviewed and human-scheduled edition" do
      authorize_schedule!
      schedule = build_schedule

      assert_empty schedule.validation_errors
      assert_equal "scheduled", schedule.workflow_state
      assert_equal Time.find_zone!("Europe/Madrid").local(2026, 9, 7), schedule.activation_at
    end

    test "accepts the human-scheduled FAST replacement" do
      schedule = DailyEditorialSchedule.load(FAST_CONFIG_PATH)

      assert_empty schedule.validation_errors
      assert_equal DailyEditorialSchedule::FAST_SCHEMA_VERSION, schedule.schema_version
      assert_equal "scheduled", schedule.workflow_state
      assert schedule.scheduled?
      assert_equal :active, schedule.phase(at: Time.find_zone!("Europe/Madrid").local(2026, 9, 5, 12))
      assert_equal %w[
        psalms_living_god psalms_servant_king psalms_hears_knows
        psalms_walk_with_god psalms_build_home psalms_every_breath
      ], schedule.expedition_pack_ids
    end

    test "FAST publication cannot bypass unresolved human copy" do
      data = YAML.safe_load_file(FAST_CONFIG_PATH, aliases: false)
      dossier = YAML.safe_load_file(Rails.root.join(data.fetch("source_dossier")), aliases: false)
      dossier.dig("fast", "runtime_export", "library_editorial")["status"] = "pending_human_validation"
      dossier.dig("fast", "runtime_export", "accessibility_copy")["status"] = "pending_human_validation"
      dossier.dig("fast", "runtime_export")["unresolved_human_copy"] = [ "pack title" ]

      Tempfile.create([ "fast-expedition-with-unresolved-copy", ".yml" ]) do |file|
        file.write(YAML.dump(dossier))
        file.flush
        schedule = DailyEditorialSchedule.new(path: FAST_CONFIG_PATH, data:)
        schedule.define_singleton_method(:source_dossier_path) { Pathname(file.path) }

        issues = schedule.validation_errors
        assert_includes issues, "source_dossier FAST library editorial must be approved"
        assert_includes issues, "source_dossier FAST accessibility copy must be approved"
        assert_includes issues, "source_dossier FAST runtime copy still has unresolved human decisions"
      end
    end

    test "distinguishes preparation authorization and exact local activation" do
      authorize_schedule!
      schedule = build_schedule
      zone = Time.find_zone!("Europe/Madrid")

      assert_equal :scheduled, schedule.phase(at: zone.local(2026, 9, 6, 23, 59, 59))
      assert_equal :active, schedule.phase(at: zone.local(2026, 9, 7, 0, 0, 0))
      assert_equal :active, schedule.phase(at: zone.local(2026, 9, 13, 23, 59, 59))
      assert_equal :expired, schedule.phase(at: zone.local(2026, 9, 14, 0, 0, 0))

      @data["publication"] = {
        "state" => "publish_ready",
        "activate_at" => "2026-09-07T00:00:00+02:00"
      }
      awaiting = build_schedule
      assert_empty awaiting.validation_errors
      assert_equal :awaiting_authorization, awaiting.phase(at: zone.local(2026, 9, 7, 12))
      refute awaiting.scheduled?
    end

    test "rejects a scheduled edition without explicit human authorization" do
      authorize_schedule!
      @data["publication"].delete("authorized_by")
      @data["publication"].delete("authorized_on")

      issues = build_schedule.validation_errors

      assert_includes issues, "publication.authorized_by is required for scheduled editions"
      assert_includes issues, "publication.authorized_on is required for scheduled editions"
    end

    test "rejects a calendar instant that is not midnight in the declared timezone" do
      @data["publication"]["state"] = "scheduled"
      @data["publication"]["activate_at"] = "2026-08-31T00:00:00+00:00"

      assert_includes build_schedule.validation_errors,
        "publication.activate_at must be local midnight at starts_on in timezone"
    end

    test "rejects copy changed after the Council digest and missing artwork" do
      @data["daily_discoveries"].first["copy"]["fr"]["title"] = "Texte change"
      @data["daily_discoveries"].last["artwork_key"] = "scripture.library.daily.missing"

      issues = build_schedule.validation_errors

      assert_includes issues, "daily discoveries changed after Council review"
      assert_includes issues, "daily_discoveries[6].artwork_key is not in the generated media manifest"
    end

    test "binds every light family to the exact artwork theme" do
      row = @data.fetch("daily_discoveries").first
      artwork_theme = Frontend::MediaManifest.fetch(row.fetch("artwork_key")).fetch("theme")
      row["light_family"] = artwork_theme == "light" ? "celestial_dark" : "celestial_light"

      issues = build_schedule.validation_errors

      assert_includes issues, "daily_discoveries[0].light_family must match the artwork theme"

      row["light_family"] = "paper"
      issues = build_schedule.validation_errors
      assert_includes issues, "daily_discoveries[0].light_family is invalid"
    end

    test "requires the Human Dramaturgy Gate for schema version two editions" do
      revision = @data.dig("council_review", "revision")
      @data["council_review"].delete("human_dramaturgy_gate")

      issues = build_schedule.validation_errors

      assert_includes issues, "council_review.human_dramaturgy_gate must PASS"

      @data["council_review"]["human_dramaturgy_gate"] = {
        "status" => "PASS", "reviewed_revision" => revision
      }
      refute_includes build_schedule.validation_errors,
        "council_review.human_dramaturgy_gate must PASS"
    end

    test "rejects a gate verdict from an older Council revision" do
      @data["schema_version"] = 2
      @data["council_review"]["revision"] = 4
      @data["council_review"]["human_dramaturgy_gate"] = {
        "status" => "PASS", "reviewed_revision" => 4
      }
      %w[art_gate experience_gate human_voice_gate truth_gate].each do |gate|
        @data["council_review"][gate]["reviewed_revision"] = 4
      end
      @data["council_review"]["art_gate"]["reviewed_revision"] = 3

      assert_includes build_schedule.validation_errors,
        "council_review.art_gate.reviewed_revision must match council_review.revision"
    end

    test "confines the source dossier to the expedition Council directory" do
      @data["source_dossier"] = "Gemfile"

      assert_includes build_schedule.validation_errors,
        "source_dossier must point to config/expeditions/*.yml"
    end

    test "binds a version two delivery to the exact dossier revision" do
      @data["schema_version"] = 2
      @data["council_review"]["revision"] = 4

      assert_includes build_schedule.validation_errors,
        "council_review.revision must match source_dossier lifecycle.current_revision"
    end

    test "requires the canonical Library contract in version two dossiers" do
      dossier_path = Rails.root.join(@data.fetch("source_dossier"))
      dossier = YAML.safe_load_file(dossier_path, aliases: false)
      dossier.delete("library_editorial")

      Tempfile.create([ "expedition-without-library", ".yml" ]) do |file|
        file.write(YAML.dump(dossier))
        file.flush
        schedule = build_schedule
        schedule.define_singleton_method(:source_dossier_path) { Pathname(file.path) }

        assert_includes schedule.validation_errors,
          "source_dossier must contain the canonical library_editorial contract"
      end
    end

    test "uses a numeric boundary when matching Bible references in filenames" do
      schedule = build_schedule

      assert schedule.send(:biblical_filename?, "prov1-listening-portrait-v1.png", [ "ot/prov/1" ])
      refute schedule.send(:biblical_filename?, "prov15-listening-portrait-v1.png", [ "ot/prov/1" ])
    end

    test "requires twenty-one unique source masters across the whole week" do
      schedule = build_schedule
      original = Frontend::MediaManifest.method(:fetch)
      shared_asset = original.call(@data.fetch("daily_discoveries").first.fetch("artwork_key"))
      Frontend::MediaManifest.define_singleton_method(:fetch) { |_key| shared_asset }

      assert_includes schedule.validation_errors,
        "daily artwork must use exactly 21 unique source masters"
    ensure
      Frontend::MediaManifest.define_singleton_method(:fetch, original) if original
    end

    test "does not allow a future edition to bypass dramaturgy with the legacy schema" do
      @data["schema_version"] = 1
      @data["starts_on"] = "2026-09-07"
      @data["ends_on"] = "2026-09-13"

      assert_includes build_schedule.validation_errors,
        "schema_version 2 is required for editions starting on or after 2026-09-07"
    end

    test "keeps local midnight boundaries when Madrid changes from summer to winter time" do
      @data["starts_on"] = "2026-10-25"
      @data["ends_on"] = "2026-10-31"
      @data["publication"]["activate_at"] = "2026-10-25T00:00:00+02:00"
      @data["publication"]["state"] = "scheduled"
      schedule = build_schedule
      zone = Time.find_zone!("Europe/Madrid")

      assert_equal zone.local(2026, 10, 25, 0, 0, 0), schedule.activation_at
      assert_equal zone.local(2026, 11, 1, 0, 0, 0), schedule.expires_at
      assert_equal 2.hours, schedule.activation_at.utc_offset
      assert_equal 1.hour, schedule.expires_at.utc_offset
      assert_equal :scheduled, schedule.phase(at: zone.local(2026, 10, 24, 23, 59, 59))
      assert_equal :active, schedule.phase(at: zone.local(2026, 10, 25, 0, 0, 0))
      assert_equal :expired, schedule.phase(at: zone.local(2026, 11, 1, 0, 0, 0))
    end

    private

      def build_schedule
        DailyEditorialSchedule.new(path: CONFIG_PATH, data: @data)
      end

      def authorize_schedule!
        @data["publication"].merge!(
          "state" => "scheduled",
          "authorized_by" => "test",
          "authorized_on" => "2026-09-05"
        )
      end
  end
end
