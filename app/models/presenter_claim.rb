class PresenterClaim < ApplicationRecord
  STATUSES = %w[pending granted refused blocked].freeze
  TIMEOUT = 60

  belongs_to :game_session

  validates :device_digest, :name, :status, :expires_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :name, length: { maximum: 40 }

  scope :pending, -> { where(status: "pending") }

  def pending? = status == "pending"
  def granted? = status == "granted"
  def refused? = status == "refused"
  def blocked? = status == "blocked"
  def expired? = expires_at <= Time.current
end
