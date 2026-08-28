class WebPushSubscription < ApplicationRecord
  belongs_to :person
  has_many :notification_deliveries, dependent: :nullify

  validates :device_token_digest, :endpoint_ciphertext, :endpoint_digest,
            :p256dh_ciphertext, :auth_ciphertext, :locale, :time_zone, presence: true
  validates :endpoint_digest, uniqueness: true
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validate :valid_time_zone

  scope :active, -> { where(revoked_at: nil) }

  def endpoint = Notifications::Cipher.decrypt(endpoint_ciphertext)
  def p256dh = Notifications::Cipher.decrypt(p256dh_ciphertext)
  def auth = Notifications::Cipher.decrypt(auth_ciphertext)

  def endpoint=(value)
    self.endpoint_digest = Notifications::Cipher.digest(value)
    self.endpoint_ciphertext = Notifications::Cipher.encrypt(value)
  end

  def p256dh=(value)
    self.p256dh_ciphertext = Notifications::Cipher.encrypt(value)
  end

  def auth=(value)
    self.auth_ciphertext = Notifications::Cipher.encrypt(value)
  end

  def active? = revoked_at.nil?

  def revoke!(at: Time.current)
    update!(revoked_at: at)
  end

  def mark_success!(at: Time.current)
    update!(last_success_at: at, last_failure_at: nil, failure_count: 0)
  end

  def mark_failure!(at: Time.current)
    update!(last_failure_at: at, failure_count: failure_count + 1)
  end

  private

    def valid_time_zone
      TZInfo::Timezone.get(time_zone)
    rescue TZInfo::InvalidTimezoneIdentifier
      errors.add(:time_zone, :invalid)
    end
end
