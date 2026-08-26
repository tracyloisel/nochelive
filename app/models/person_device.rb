class PersonDevice < ApplicationRecord
  LIVE_WINDOW = 25.seconds

  belongs_to :person

  validates :device_token, presence: true
  validates :person_id, uniqueness: { scope: :device_token }

  scope :live, -> { where(last_seen_at: LIVE_WINDOW.ago..) }

  def live?
    last_seen_at.present? && last_seen_at >= LIVE_WINDOW.ago
  end
end
