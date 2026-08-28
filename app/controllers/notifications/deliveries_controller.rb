module Notifications
  class DeliveriesController < BaseController
    def open
      delivery = push_person.notification_deliveries.find(params[:id])
      Notifications::AcknowledgeOpen.call(delivery:, person: push_person, path: params[:path])
      head :no_content
    end
  end
end
