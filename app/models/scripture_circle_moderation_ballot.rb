class ScriptureCircleModerationBallot < ApplicationRecord
  CHOICES = %w[yes no].freeze

  belongs_to :scripture_circle_moderation_proposal
  belongs_to :ward
  belongs_to :voter_person, class_name: "Person", optional: true
  has_many :scripture_circle_moderation_ballot_revisions, dependent: :destroy

  validates :choice, :cast_at, presence: true
  validates :choice, inclusion: { in: CHOICES }
  validates :voter_person_id, uniqueness: { scope: :scripture_circle_moderation_proposal_id }, allow_nil: false
  validate :eligible_voter
  validate :open_proposal

  private

    def eligible_voter
      return errors.add(:voter_person, :blank) if voter_person.blank?
      valid = voter_person.ward_id == ward_id && scripture_circle_moderation_proposal&.ward_id == ward_id
      errors.add(:voter_person, :invalid) unless valid
    end

    def open_proposal
      proposal = scripture_circle_moderation_proposal
      effective_cast_at = cast_at || Time.current
      errors.add(:scripture_circle_moderation_proposal, :closed) unless proposal&.open? && proposal.ends_at > effective_cast_at
    end
end
