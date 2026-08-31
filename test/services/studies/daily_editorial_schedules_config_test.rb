require "test_helper"

module Studies
  class DailyEditorialSchedulesConfigTest < ActiveSupport::TestCase
    test "every weekly file is a complete valid and Council-reviewed edition" do
      schedules.each do |schedule|
        rows = schedule.discoveries

        assert_empty schedule.validation_errors, schedule.path.to_s
        assert_equal 7, rows.size, schedule.id
        assert_equal (schedule.starts_on..schedule.ends_on).map(&:iso8601), rows.pluck("scheduled_on"), schedule.id
        assert_equal [ *Array.new(6, "discovery"), "contemplation" ], rows.pluck("kind"), schedule.id
        assert_nil rows.last["pack_id"], schedule.id
        if schedule.expedition_pack_ids.any?
          assert rows.first(6).all? { |row| row["pack_id"].present? }, schedule.id
        else
          assert rows.all? { |row| row["pack_id"].nil? }, schedule.id
        end
      end
    end

    test "stored digests protect the exact copy reviewed by the Council" do
      schedules.each do |schedule|
        assert_equal schedule.expected_discoveries_digest,
          StudyQuizVersion.content_digest_for(schedule.discoveries),
          schedule.id
        next unless schedule.schema_version == DailyEditorialSchedule::SCHEMA_VERSION

        assert_equal schedule.expected_artwork_digest,
          schedule.current_artwork_digest,
          schedule.id
      end
    end

    test "all per-entry gates cover the frozen revision" do
      schedules.each do |schedule|
        schedule.discoveries.each do |row|
          %w[truth_gate experience_gate].each do |gate_name|
            gate = row.fetch(gate_name)
            assert_equal "PASS", gate.fetch("status"), row.fetch("id")
            assert_equal row.fetch("revision"), gate.fetch("reviewed_revision"), row.fetch("id")
          end
        end
      end
    end

    test "schedule identifiers windows and filenames remain unambiguous" do
      assert schedules.any?
      assert_equal schedules.map(&:id).uniq.size, schedules.size
      assert_equal schedules.map { |schedule| [ schedule.program_slug, schedule.study_unit_slug ] }.uniq.size, schedules.size

      schedules.each do |schedule|
        assert schedule.path.basename.to_s.start_with?(schedule.starts_on.iso8601), schedule.path.to_s
      end
    end

    private

      def schedules
        @schedules ||= DailyEditorialSchedule.all
      end
  end
end
