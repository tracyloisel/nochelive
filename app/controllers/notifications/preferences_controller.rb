module Notifications
  class PreferencesController < BaseController
    def update
      preference = Notifications::UpdatePreferences.call(
        person: push_person,
        device_token: device_token,
        category: params.require(:category),
        enabled: params.require(:enabled),
        attributes: preference_params
      )
      render json: {
        status: "updated",
        verses_enabled: preference.verses_enabled?,
        challenges_enabled: preference.challenges_enabled?
      }
    rescue Notifications::UpdatePreferences::Error, ActiveRecord::RecordInvalid, ActionController::ParameterMissing
      render json: { error: "invalid_preferences" }, status: :unprocessable_entity
    end

    private

      def preference_params
        params.permit(:verse_frequency, :verse_local_time, :quiet_hours_start, :quiet_hours_end).to_h
      end
  end
end
