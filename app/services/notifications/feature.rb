module Notifications
  module Feature
    module_function

    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("WEB_PUSH_ENABLED", "false"))
    end

    def delivery_enabled?
      enabled? && ActiveModel::Type::Boolean.new.cast(ENV.fetch("WEB_PUSH_DELIVERY_ENABLED", "false"))
    end

    def vapid_configured?
      public_key.present? && private_key.present? && subject.present?
    end

    def public_key
      ENV["VAPID_PUBLIC_KEY"].to_s.delete("=")
    end

    def private_key
      ENV["VAPID_PRIVATE_KEY"].to_s
    end

    def subject
      ENV["VAPID_SUBJECT"].to_s
    end
  end
end
