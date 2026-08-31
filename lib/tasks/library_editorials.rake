namespace :library_editorials do
  desc "Validate every code-versioned Library daily editorial schedule"
  task validate: :environment do
    schedules = Studies::DailyEditorialSchedule.all
    abort "No Library editorial schedules found." if schedules.empty?

    schedules.each do |schedule|
      if schedule.workflow_state == "draft" && schedule.validation_errors.any?
        puts [ schedule.id.presence || schedule.path.basename, "draft", "draft_unvalidated" ].join("\t")
        next
      end

      schedule.validate!
      puts [
        schedule.id,
        schedule.workflow_state,
        schedule.phase,
        schedule.expected_discoveries_digest,
        schedule.expected_artwork_digest.presence || "legacy-artwork-contract"
      ].join("\t")
    end
  end

  desc "Show workflow and calendar status without publishing anything"
  task status: :environment do
    Studies::DailyEditorialSchedule.all.each do |schedule|
      issues = schedule.validation_errors
      status = issues.empty? ? schedule.phase : :invalid
      puts [ schedule.id, schedule.workflow_state, status, issues.join(" | ") ].join("\t")
    end
  end

  desc "Verify database readiness before a human schedules a Library edition"
  task preflight: :environment do
    schedules = Studies::DailyEditorialSchedule.all.reject { |schedule| schedule.workflow_state == "draft" }
    abort "No publish-ready or scheduled Library editorial schedules found." if schedules.empty?

    results = schedules.map { |schedule| Studies::DailyEditorialPreflight.call(schedule:) }
    results.each do |result|
      puts [
        result.schedule_id,
        result.ready ? "ready" : "blocked",
        result.study_unit_id,
        result.quiz_version_id,
        result.message
      ].join("\t")
    end

    failures = results.reject(&:ready)
    abort "#{failures.size} Library editorial schedule(s) failed preflight." if failures.any?
  end

  desc "Publish only schedules carrying explicit human authorization"
  task publish_scheduled: :environment do
    results = Studies::PublishScheduledDailyEditorials.call
    results.each do |result|
      puts [ result.schedule_id, result.workflow_state, result.phase, result.database_state, result.message ].join("\t")
    end

    failures = results.select(&:error?)
    abort "#{failures.size} Library editorial schedule(s) failed." if failures.any?
  end
end
