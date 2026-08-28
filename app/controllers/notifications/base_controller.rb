module Notifications
  class BaseController < ApplicationController
    before_action :require_feature
    before_action :require_push_person

    private

      def require_feature
        head :not_found unless Notifications::Feature.enabled?
      end

      def require_push_person
        return if performed?
        return if current_street_person

        render json: { error: "profile_required" }, status: :unauthorized
      end

      def push_person = current_street_person

      def user_agent_family
        agent = request.user_agent.to_s
        return "Edge" if agent.include?("Edg/")
        return "Chrome" if agent.include?("Chrome/") || agent.include?("CriOS/")
        return "Safari" if agent.include?("Safari/")
        return "Firefox" if agent.include?("Firefox/") || agent.include?("FxiOS/")

        "Other"
      end
  end
end
