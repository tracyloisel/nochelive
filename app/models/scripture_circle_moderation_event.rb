class ScriptureCircleModerationEvent < ApplicationRecord
  EVENT_TYPES = %w[opened ballot_cast ballot_changed canceled_by_author resolution_started resolved resolution_failed].freeze

  belongs_to :proposal, class_name: "ScriptureCircleModerationProposal"
  belongs_to :post, class_name: "ScriptureCirclePost"
  belongs_to :ward
  belongs_to :actor_person, class_name: "Person", optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :same_scope

  private

    def same_scope
      return if proposal.blank? || post.blank?
      errors.add(:base, :invalid) unless proposal.scripture_circle_post_id == post_id && proposal.ward_id == ward_id && post.ward_id == ward_id
    end
end
