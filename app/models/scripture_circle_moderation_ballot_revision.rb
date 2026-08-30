class ScriptureCircleModerationBallotRevision < ApplicationRecord
  belongs_to :scripture_circle_moderation_ballot
  belongs_to :proposal, class_name: "ScriptureCircleModerationProposal"
  belongs_to :ward
  belongs_to :voter_person, class_name: "Person", optional: true

  validates :new_choice, inclusion: { in: ScriptureCircleModerationBallot::CHOICES }
  validates :previous_choice, inclusion: { in: ScriptureCircleModerationBallot::CHOICES }, allow_nil: true
  validate :same_scope

  private

    def same_scope
      ballot = scripture_circle_moderation_ballot
      return if ballot.blank?
      valid = ballot.scripture_circle_moderation_proposal_id == proposal_id && ballot.ward_id == ward_id &&
        ballot.voter_person_id == voter_person_id
      errors.add(:base, :invalid) unless valid
    end
end
