class ScriptureCircleModerationProposal < ApplicationRecord
  STATUSES = %w[open kept censored canceled_by_author].freeze
  REASON_KEYS = %w[uncharitable personal_attack private_information off_topic other].freeze
  POLICY_VERSION = "ward-reports-v2"
  MINIMUM_DURATION = 2.days

  belongs_to :scripture_circle_post
  belongs_to :ward
  belongs_to :proposer_person, class_name: "Person", optional: true
  belongs_to :post_revision, class_name: "ScriptureCirclePostRevision"
  has_many :scripture_circle_moderation_ballots, dependent: :destroy
  has_many :scripture_circle_moderation_events, foreign_key: :proposal_id, dependent: :destroy

  validates :reason_key, :status, :starts_at, :ends_at, :policy_version, presence: true
  validates :reason_key, inclusion: { in: REASON_KEYS }
  validates :reason_details, length: { maximum: 240 }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :yes_count, :no_count, :valid_ballot_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :minimum_duration
  validate :same_ward
  validate :eligible_proposer, on: :create

  scope :open, -> { where(status: "open") }
  scope :due, ->(at = Time.current) { open.where(ends_at: ..at) }

  def open? = status == "open"
  def total_count = yes_count + no_count
  def yes_percentage = percentage(yes_count)
  def no_percentage = percentage(no_count)

  def results_payload
    {
      id:,
      status:,
      yes_count:,
      no_count:,
      total_count:,
      yes_percentage:,
      no_percentage:,
      ends_at: ends_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end

  private

    def percentage(count)
      return 0 if total_count.zero?
      ((count.to_f / total_count) * 100).round
    end

    def minimum_duration
      return if starts_at.blank? || ends_at.blank?
      errors.add(:ends_at, :too_short) if ends_at < starts_at + MINIMUM_DURATION
    end

    def same_ward
      return if scripture_circle_post.blank? || post_revision.blank?
      valid = scripture_circle_post.ward_id == ward_id && post_revision.ward_id == ward_id &&
        post_revision.scripture_circle_post_id == scripture_circle_post_id
      errors.add(:ward, :invalid) unless valid
    end

    def eligible_proposer
      errors.add(:proposer_person, :blank) if proposer_person.blank?
      errors.add(:proposer_person, :invalid) if proposer_person && proposer_person.ward_id != ward_id
    end
end
