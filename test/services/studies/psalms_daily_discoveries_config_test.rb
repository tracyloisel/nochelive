require "test_helper"

module Studies
  class PsalmsDailyDiscoveriesConfigTest < ActiveSupport::TestCase
    CONFIG_PATH = Rails.root.join("config/study/psalms_daily_discoveries_2026.yml")

    test "the reviewed Psalms edition contains one valid editorial for every day" do
      data = configuration
      rows = data.fetch("daily_discoveries")
      starts_on = Date.iso8601(data.fetch("starts_on"))
      ends_on = Date.iso8601(data.fetch("ends_on"))
      version = StudyQuizVersion.new(
        study_unit: StudyUnit.new(starts_on:, ends_on:),
        content: {
          "expedition" => { "pack_ids" => data.fetch("expedition_pack_ids") },
          "daily_discoveries" => rows
        }
      )

      assert_equal 7, rows.size
      assert_equal (starts_on..ends_on).map(&:iso8601), rows.pluck("scheduled_on")
      assert_equal [ *Array.new(6, "discovery"), "contemplation" ], rows.pluck("kind")
      assert rows.first(6).all? { |row| row["pack_id"].present? }
      assert_nil rows.last["pack_id"]
      assert_equal [ "Europe/Madrid" ], rows.pluck("timezone").uniq
      assert_empty version.daily_discovery_publication_errors
    end

    test "the stored digest protects the exact council-reviewed copy" do
      data = configuration

      assert_equal data.fetch("expected_discoveries_digest"),
        StudyQuizVersion.content_digest_for(data.fetch("daily_discoveries"))
    end

    test "every editorial resolves to its responsive biblical artwork" do
      assets = YAML.safe_load_file(Rails.root.join("config/media/responsive.yml"), aliases: false).fetch("assets")

      configuration.fetch("daily_discoveries").each do |row|
        asset = assets.fetch(row.fetch("artwork_key"))
        masters = [ asset.fetch("source"), *asset.fetch("sources").values ]
        assert_equal "library_daily_hero", asset.fetch("role")
        assert_equal %w[tablet landscape], asset.fetch("sources").keys
        assert masters.all? { |master| master.match?(%r{/ps\d}) }, row.fetch("id")
      end
    end

    test "all council gates cover the frozen revision" do
      configuration.fetch("daily_discoveries").each do |row|
        %w[truth_gate experience_gate].each do |gate_name|
          gate = row.fetch(gate_name)
          assert_equal "PASS", gate.fetch("status")
          assert_equal row.fetch("revision"), gate.fetch("reviewed_revision")
        end
      end
    end

    private

      def configuration
        @configuration ||= YAML.safe_load_file(CONFIG_PATH, aliases: false)
      end
  end
end
