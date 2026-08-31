module Studies
  # Imports every explicitly authorized Library edition into its future study
  # unit. Publishing can happen days ahead; Expeditions::DailyDiscovery still
  # exposes only the row matching the exact local calendar date.
  class PublishScheduledDailyEditorials
    Result = Data.define(
      :schedule_id, :path, :workflow_state, :phase, :database_state,
      :quiz_version_id, :message
    ) do
      def error? = database_state == :error
      def published? = %i[published already_published].include?(database_state)
    end

    class Error < StandardError; end

    def self.call(at: Time.current, paths: nil, root: DailyEditorialSchedule::ROOT)
      new(at:, paths:, root:).call
    end

    def initialize(at:, paths:, root:)
      @at = at
      @paths = paths
      @root = root
    end

    def call
      schedule_paths.map { |path| process(path) }
    end

    private

      def schedule_paths
        paths = @paths.nil? ? DailyEditorialSchedule.paths(root: @root) : Array(@paths)
        root = Pathname(@root).realpath

        paths.map do |path|
          candidate = Pathname(path).realpath
          raise Error, "schedule path must remain inside #{root}" unless candidate.dirname == root

          candidate
        end
      rescue Errno::ENOENT => error
        raise Error, "schedule path is not readable: #{error.message}"
      end

      def process(path)
        schedule = DailyEditorialSchedule.load(path)
        phase = schedule.phase(at: @at)
        if schedule.workflow_state == "draft"
          return result(
            schedule, phase:, database_state: :not_authorized,
            message: "Council draft is intentionally ignored"
          )
        end

        schedule.validate!
        unless schedule.scheduled?
          return result(
            schedule, phase:, database_state: :not_authorized,
            message: "Council output awaits human scheduling"
          )
        end

        unit = resolve_unit(schedule)
        source = unit.published_quiz
        raise Error, "study unit has no published quiz version" unless source
        ensure_pack_contract!(schedule, source)

        if same_discoveries?(source.daily_discoveries, schedule.discoveries)
          return result(
            schedule, phase:, database_state: :already_published,
            quiz_version_id: source.id, message: "Reviewed edition is already stored in the immutable quiz version"
          )
        end

        if phase == :expired
          raise Error, "publication window expired before this edition was imported"
        end

        published = PublishDailyDiscoveries.call(
          study_unit: unit,
          discoveries: schedule.discoveries,
          expected_discoveries_digest: schedule.expected_discoveries_digest,
          at: @at
        )
        result(
          schedule, phase:, database_state: :published,
          quiz_version_id: published.id,
          message: "Edition stored; screen activation remains #{schedule.activation_at.iso8601}"
        )
      rescue DailyEditorialSchedule::Error, Error, PublishDailyDiscoveries::Error, ActiveRecord::RecordNotFound => error
        Result.new(
          schedule_id: defined?(schedule) && schedule&.id.presence,
          path: path.to_s,
          workflow_state: defined?(schedule) && schedule&.workflow_state.presence,
          phase: defined?(phase) && phase,
          database_state: :error,
          quiz_version_id: nil,
          message: error.message
        )
      end

      def resolve_unit(schedule)
        program = StudyProgram.find_by!(slug: schedule.program_slug)
        program.study_units.find_by!(
          slug: schedule.study_unit_slug,
          starts_on: schedule.starts_on,
          ends_on: schedule.ends_on
        )
      end

      def ensure_pack_contract!(schedule, source)
        return if source.expedition_pack_ids == schedule.expedition_pack_ids

        raise Error, "published expedition packs no longer match the Council-reviewed edition"
      end

      def same_discoveries?(left, right)
        StudyQuizVersion.content_digest_for(left) == StudyQuizVersion.content_digest_for(right)
      end

      def result(schedule, phase:, database_state:, message:, quiz_version_id: nil)
        Result.new(
          schedule_id: schedule.id,
          path: schedule.path.to_s,
          workflow_state: schedule.workflow_state,
          phase:,
          database_state:,
          quiz_version_id:,
          message:
        )
      end
  end
end
