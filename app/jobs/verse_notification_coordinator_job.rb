class VerseNotificationCoordinatorJob < ApplicationJob
  queue_as :maintenance

  def perform
    Notifications::ScheduleVerses.call
  end
end
