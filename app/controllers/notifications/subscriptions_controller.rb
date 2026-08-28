module Notifications
  class SubscriptionsController < BaseController
    def create
      row = Notifications::Subscribe.call(
        person: push_person,
        device_token: device_token,
        subscription: subscription_params,
        locale: current_locale,
        time_zone: params[:time_zone],
        user_agent_family: user_agent_family,
        reassign: params[:reassign]
      )
      if params[:category].present?
        Notifications::UpdatePreferences.call(
          person: push_person,
          device_token: device_token,
          category: params[:category],
          enabled: true,
          attributes: preference_params
        )
        Notifications::RecordPrompt.call(
          person: push_person,
          device_token: device_token,
          category: params[:category],
          result: "activated",
          context: params[:context].presence || "profile"
        )
      end
      render json: { status: "subscribed", subscription_id: row.id, category: params[:category] }, status: :created
    rescue Notifications::Subscribe::Error => error
      render json: { error: error.code }, status: error.code == :reassignment_required ? :conflict : :unprocessable_entity
    rescue Notifications::UpdatePreferences::Error, ActiveRecord::RecordInvalid, ArgumentError => error
      render json: { error: "invalid_preferences" }, status: :unprocessable_entity
    end

    def destroy
      count = Notifications::Unsubscribe.call(
        person: push_person,
        device_token: device_token,
        endpoint: params[:endpoint]
      )
      render json: { status: "unsubscribed", removed: count }
    end

    private

      def subscription_params
        params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ]).to_h
      end

      def preference_params
        params.permit(:verse_frequency, :verse_local_time, :quiet_hours_start, :quiet_hours_end).to_h
      end
  end
end
