class NotificationSettingsController < ApplicationController
  def show
    return head :not_found unless Notifications::Feature.enabled?

    unless current_street_person
      session[:street_return] = "notification_settings"
      redirect_to street_profile_path, alert: I18n.t("flashes.profile_required")
      return
    end

    device_token
    @person = current_street_person
  end
end
