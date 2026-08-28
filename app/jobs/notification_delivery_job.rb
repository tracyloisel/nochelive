class NotificationDeliveryJob < ApplicationJob
  retry_on Notifications::Deliver::TransientError, wait: :polynomially_longer, attempts: 5, jitter: 0.15
  discard_on ActiveJob::DeserializationError

  def perform(delivery)
    Notifications::Deliver.call(delivery:)
  end
end
