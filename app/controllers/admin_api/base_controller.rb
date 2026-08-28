module AdminApi
  class BaseController < ActionController::API
    before_action :authenticate_admin!

    private

      def authenticate_admin!
        expected = ENV["NOCHE_ADMIN_API_TOKEN"].to_s
        supplied = request.authorization.to_s.delete_prefix("Bearer ")
        valid = expected.length >= 32 && supplied.present? && secure_digest(expected) == secure_digest(supplied)
        head :unauthorized unless valid
      end

      def secure_digest(value)
        OpenSSL::Digest::SHA256.hexdigest(value)
      end

      def admin_audit!(action, fields = {})
        Rails.logger.info({ event: "admin_api", action:, **fields }.to_json)
      end
  end
end
