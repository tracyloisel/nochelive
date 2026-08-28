module Notifications
  class Unsubscribe
    def self.call(person:, device_token:, endpoint: nil)
      return 0 unless person && device_token.present?

      scope = person.web_push_subscriptions.where(
        device_token_digest: Notifications::Cipher.device_digest(device_token)
      )
      scope = scope.where(endpoint_digest: Notifications::Cipher.digest(endpoint)) if endpoint.present?
      count = scope.count
      scope.destroy_all
      count
    end
  end
end
