require "test_helper"

module Studies
  class DailyEditorialScheduleTest < ActiveSupport::TestCase
    CONFIG_PATH = Rails.root.join("config/study/library_daily_editorials/2026-08-31-psalms-102-150.yml")

    setup do
      @data = YAML.safe_load_file(CONFIG_PATH, aliases: false)
    end

    test "accepts the canonical Council-reviewed and human-scheduled edition" do
      schedule = build_schedule

      assert_empty schedule.validation_errors
      assert_equal "scheduled", schedule.workflow_state
      assert_equal Time.find_zone!("Europe/Madrid").local(2026, 8, 31), schedule.activation_at
    end

    test "distinguishes preparation authorization and exact local activation" do
      schedule = build_schedule
      zone = Time.find_zone!("Europe/Madrid")

      assert_equal :scheduled, schedule.phase(at: zone.local(2026, 8, 30, 23, 59, 59))
      assert_equal :active, schedule.phase(at: zone.local(2026, 8, 31, 0, 0, 0))
      assert_equal :active, schedule.phase(at: zone.local(2026, 9, 6, 23, 59, 59))
      assert_equal :expired, schedule.phase(at: zone.local(2026, 9, 7, 0, 0, 0))

      @data["publication"] = {
        "state" => "publish_ready",
        "activate_at" => "2026-08-31T00:00:00+02:00"
      }
      awaiting = build_schedule
      assert_empty awaiting.validation_errors
      assert_equal :awaiting_authorization, awaiting.phase(at: zone.local(2026, 8, 31, 12))
      refute awaiting.scheduled?
    end

    test "rejects a scheduled edition without explicit human authorization" do
      @data["publication"].delete("authorized_by")
      @data["publication"].delete("authorized_on")

      issues = build_schedule.validation_errors

      assert_includes issues, "publication.authorized_by is required for scheduled editions"
      assert_includes issues, "publication.authorized_on is required for scheduled editions"
    end

    test "rejects a calendar instant that is not midnight in the declared timezone" do
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

    test "requires the Human Dramaturgy Gate for schema version two editions" do
      @data["schema_version"] = 2

      issues = build_schedule.validation_errors

      assert_includes issues, "council_review.human_dramaturgy_gate must PASS"

      @data["council_review"]["revision"] = 4
      @data["council_review"]["human_dramaturgy_gate"] = {
        "status" => "PASS", "reviewed_revision" => 4
      }
      %w[art_gate experience_gate human_voice_gate truth_gate].each do |gate|
        @data["council_review"][gate]["reviewed_revision"] = 4
      end
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
      @data["schema_version"] = 2

      assert_includes build_schedule.validation_errors,
        "source_dossier must contain the canonical library_editorial contract"
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
      @data["starts_on"] = "2026-09-07"
      @data["ends_on"] = "2026-09-13"

      assert_includes build_schedule.validation_errors,
        "schema_version 2 is required for editions starting on or after 2026-09-07"
    end

    test "keeps local midnight boundaries when Madrid changes from summer to winter time" do
      @data["starts_on"] = "2026-10-25"
      @data["ends_on"] = "2026-10-31"
      @data["publication"]["activate_at"] = "2026-10-25T00:00:00+02:00"
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
  end
end
