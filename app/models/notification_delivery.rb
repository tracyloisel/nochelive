class NotificationDelivery < ApplicationRecord
  KINDS = %w[daily_verse study_reading duel_invitation duel_reminder duel_result].freeze
  STATUSES = %w[queued sending sent failed opened cancelled].freeze
  TRANSITIONAL_KINDS = %w[duel_invitation duel_reminder duel_result].freeze

  belongs_to :web_push_subscription, optional: true
  belongs_to :person
  belongs_to :subject, polymorphic: true, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :dedupe_key, presence: true, uniqueness: true
  validates :destination, presence: true, format: { with: %r{\A/(?!/)[^\\\r\n]*\z} }
  validate :same_person_as_subscription

  scope :pending, -> { where(status: %w[queued sending]) }

  def transactional? = TRANSITIONAL_KINDS.include?(kind)
  STATUSES.each { |value| define_method("#{value}?") { status == value } }

  def cancel!(code: nil)
    update!(status: "cancelled", cancelled_at: Time.current, error_code: code)
  end

  private

    def same_person_as_subscription
      return unless web_push_subscription && person_id
      return if web_push_subscription.person_id == person_id

      errors.add(:person, :invalid)
    end
end
