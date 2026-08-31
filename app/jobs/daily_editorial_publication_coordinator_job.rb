class DailyEditorialPublicationCoordinatorJob < ApplicationJob
  queue_as :maintenance

  def perform(at: Time.current)
    results = Studies::PublishScheduledDailyEditorials.call(at:)
    results.each do |result|
      Rails.logger.info(
        event: "library_daily_editorial_publication",
        schedule_id: result.schedule_id,
        workflow_state: result.workflow_state,
        phase: result.phase,
        database_state: result.database_state,
        quiz_version_id: result.quiz_version_id,
        message: result.message
      )
    end

    failures = results.select(&:error?)
    return results if failures.empty?

    raise Studies::PublishScheduledDailyEditorials::Error,
      failures.map { |failure| "#{failure.path}: #{failure.message}" }.join(" | ")
  end
end
