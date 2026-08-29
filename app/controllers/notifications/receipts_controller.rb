module Notifications
  class ReceiptsController < ApplicationController
    skip_forgery_protection

    def create
      delivery = NotificationDelivery.find_signed(params[:token], purpose: AcknowledgeReceipt::PURPOSE)
      return head :not_found unless delivery

      AcknowledgeReceipt.call(delivery:)
      head :no_content
    end
  end
end
