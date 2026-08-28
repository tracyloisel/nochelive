module Notifications
  module Cipher
    module_function

    PURPOSE = "noche-live/web-push-subscription/v1".freeze

    def encrypt(value)
      encryptor.encrypt_and_sign(value.to_s, purpose: PURPOSE)
    end

    def decrypt(value)
      encryptor.decrypt_and_verify(value.to_s, purpose: PURPOSE)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    def digest(value)
      OpenSSL::HMAC.hexdigest("SHA256", digest_key, value.to_s)
    end

    def device_digest(value)
      OpenSSL::HMAC.hexdigest("SHA256", digest_key, "device:#{value}")
    end

    def encryptor
      @encryptor ||= ActiveSupport::MessageEncryptor.new(
        Rails.application.key_generator.generate_key(PURPOSE, 32),
        cipher: "aes-256-gcm",
        serializer: JSON
      )
    end

    def digest_key
      @digest_key ||= Rails.application.key_generator.generate_key("#{PURPOSE}/digest", 32)
    end
  end
end
