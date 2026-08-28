module Notifications
  class PromptStatesController < BaseController
    def update
      state = Notifications::RecordPrompt.call(
        person: push_person,
        device_token: device_token,
        category: params.require(:category),
        result: params.require(:result),
        context: params.require(:context)
      )
      render json: { status: "recorded", snoozed_until: state.snoozed_until&.iso8601 }
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ActionController::ParameterMissing, ArgumentError
      render json: { error: "invalid_prompt_state" }, status: :unprocessable_entity
    end
  end
end
