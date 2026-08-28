class IdentityTransfer < ApplicationRecord
  class InvalidToken < StandardError; end

  LIFETIME = 5.minutes
  DIGEST_KEY = "identity-transfer-token"
  ENCRYPTION_KEY = "identity-transfer-payload"

  validates :token_digest, :encrypted_payload, :expires_at, presence: true

  def self.issue!(payload)
    token = SecureRandom.urlsafe_base64(32)
    create!(
      token_digest: digest(token),
      encrypted_payload: encryptor.encrypt_and_sign(payload.to_json),
      expires_at: LIFETIME.from_now
    )
    token
  end

  def self.consume!(token)
    raise InvalidToken if token.blank?

    transaction do
      transfer = lock.find_by(token_digest: digest(token))
      raise InvalidToken unless transfer
      raise InvalidToken if transfer.expires_at <= Time.current

      payload = JSON.parse(encryptor.decrypt_and_verify(transfer.encrypted_payload))
      transfer.destroy!
      payload
    end
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, JSON::ParserError
    raise InvalidToken
  end

  def self.prune_expired!
    where(expires_at: ..Time.current).delete_all
  end

  def self.digest(token)
    OpenSSL::HMAC.hexdigest("SHA256", digest_secret, token.to_s)
  end
  private_class_method :digest

  def self.digest_secret
    Rails.application.key_generator.generate_key(DIGEST_KEY, 32)
  end
  private_class_method :digest_secret

  def self.encryptor
    key = Rails.application.key_generator.generate_key(ENCRYPTION_KEY, 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
  private_class_method :encryptor
end
