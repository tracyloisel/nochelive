class NotificationPromptState < ApplicationRecord
  CATEGORIES = %w[verses challenges].freeze
  RESULTS = %w[dismissed selected system_denied activated].freeze
  CONTEXTS = %w[challenge_sent challenge_inbox challenge_result study_completed profile].freeze
  SNOOZE = 30.days

  belongs_to :person_device

  validates :category, inclusion: { in: CATEGORIES }
  validates :category, uniqueness: { scope: :person_device_id }
  validates :last_result, inclusion: { in: RESULTS }, allow_nil: true
  validates :offer_context, inclusion: { in: CONTEXTS }, allow_nil: true

  scope :system_denied, -> { where(last_result: "system_denied") }

  def snoozed?(at: Time.current)
    snoozed_until.present? && snoozed_until > at
  end
end
