class NightNotificationCoordinatorJob < ApplicationJob
  queue_as :maintenance

  def perform(at: Time.current)
    Notifications::ScheduleNights.call(at:)
  end
end
