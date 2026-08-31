class ScriptureCircleConversationVote < ApplicationRecord
  DIRECTIONS = %w[up down].freeze

  belongs_to :conversation_root, class_name: "ScriptureCirclePost", inverse_of: :scripture_circle_conversation_votes
  belongs_to :ward
  belongs_to :voter_person, class_name: "Person", inverse_of: :scripture_circle_conversation_votes

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :voter_person_id, uniqueness: { scope: :conversation_root_id }
  validate :conversation_root_is_visible_root
  validate :voter_belongs_to_ward
  validate :not_author_vote

  def score = direction == "up" ? 1 : -1

  private

    def conversation_root_is_visible_root
      return if conversation_root.blank?
      return if conversation_root.conversation_root? && conversation_root.status == "visible" &&
        conversation_root.kind.in?(%w[question reflection]) && conversation_root.ward_id == ward_id

      errors.add(:conversation_root, :invalid)
    end

    def voter_belongs_to_ward
      return if voter_person.blank? || ward.blank?
      errors.add(:voter_person, :invalid) unless voter_person.ward_id == ward_id
    end

    def not_author_vote
      return if conversation_root.blank? || voter_person_id.blank?
      errors.add(:voter_person, :invalid) if conversation_root.person_id == voter_person_id
    end
end
