module AdminApi
  class BaseController < ActionController::API
    AUDIT_ACTOR_ENV = "NOCHE_ADMIN_API_AUDIT_ACTOR"
    AUDIT_ACTOR_MAX_LENGTH = 120

    before_action :authenticate_admin!

    private

      def authenticate_admin!
        expected = ENV["NOCHE_ADMIN_API_TOKEN"].to_s
        supplied = request.authorization.to_s.delete_prefix("Bearer ")
        valid = expected.length >= 32 && supplied.present? && secure_digest(expected) == secure_digest(supplied)
        return head :unauthorized unless valid

        # The bearer token is the only authenticated principal in this API.
        # Keep a server-owned, stable label in the immutable WardEvent audit;
        # a request parameter must never be able to claim another identity.
        @admin_audit_actor = configured_audit_actor(expected)
      end

      def secure_digest(value)
        OpenSSL::Digest::SHA256.hexdigest(value)
      end

      def admin_audit_actor
        @admin_audit_actor || raise("Admin audit actor unavailable")
      end

      def admin_audit!(action, fields = {})
        safe_fields = fields.to_h.symbolize_keys.except(:event, :action, :actor)
        Rails.logger.info(safe_fields.merge(event: "admin_api", action:, actor: admin_audit_actor).to_json)
      end

      def configured_audit_actor(token)
        configured = ENV.fetch(AUDIT_ACTOR_ENV, "").to_s.squish
        return configured.first(AUDIT_ACTOR_MAX_LENGTH) if configured.present?

        "admin-token:#{secure_digest(token).first(16)}"
      end
  end
end
