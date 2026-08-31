module Studies
  # Read-only operational check run before a human changes an edition from
  # publish_ready to scheduled. It proves that the dated programme, week and
  # immutable base quiz already exist and still match the Council pack scope.
  class DailyEditorialPreflight
    Result = Data.define(
      :schedule_id, :path, :ready, :program_id, :study_unit_id,
      :quiz_version_id, :message
    )

    def self.call(schedule:)
      new(schedule:).call
    end

    def initialize(schedule:)
      @schedule = schedule
    end

    def call
      schedule.validate!
      return result(ready: false, message: "Council draft is not ready for scheduling") if
        schedule.workflow_state == "draft"

      program = StudyProgram.find_by!(slug: schedule.program_slug)
      raise DailyEditorialSchedule::Error, "study program is not published" unless program.status == "published"

      unit = program.study_units.find_by!(
        slug: schedule.study_unit_slug,
        starts_on: schedule.starts_on,
        ends_on: schedule.ends_on
      )
      raise DailyEditorialSchedule::Error, "study unit is not published" unless unit.status == "published"

      quiz = unit.published_quiz
      raise ActiveRecord::RecordNotFound, "study unit has no published quiz version" unless quiz
      unless quiz.published_at.present? && quiz.published_at <= Time.current && quiz.content_digest_current?
        raise DailyEditorialSchedule::Error, "published base quiz is not current"
      end
      unless quiz.expedition_pack_ids == schedule.expedition_pack_ids
        raise DailyEditorialSchedule::Error,
          "published expedition packs no longer match the Council-reviewed edition"
      end

      result(
        ready: true,
        program_id: program.id,
        study_unit_id: unit.id,
        quiz_version_id: quiz.id,
        message: "Programme, dated week and published base quiz are ready"
      )
    rescue DailyEditorialSchedule::Error, ActiveRecord::RecordNotFound => error
      result(ready: false, message: error.message)
    end

    private

      attr_reader :schedule

      def result(ready:, message:, program_id: nil, study_unit_id: nil, quiz_version_id: nil)
        Result.new(
          schedule_id: schedule.id.presence,
          path: schedule.path.to_s,
          ready:,
          program_id:,
          study_unit_id:,
          quiz_version_id:,
          message:
        )
      end
  end
end
