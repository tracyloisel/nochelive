class ScriptureCirclePostVote < ApplicationRecord
  DIRECTIONS = %w[up down].freeze

  belongs_to :scripture_circle_post, inverse_of: :scripture_circle_post_votes
  belongs_to :ward
  belongs_to :voter_person, class_name: "Person", inverse_of: :scripture_circle_post_votes

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :voter_person_id, uniqueness: { scope: :scripture_circle_post_id }
  validate :post_is_visible_reply
  validate :voter_belongs_to_ward
  validate :not_author_vote

  def score = direction == "up" ? 1 : -1

  private

    def post_is_visible_reply
      return if scripture_circle_post.blank?
      return if scripture_circle_post.parent_id.present? && scripture_circle_post.kind == "reply" &&
        scripture_circle_post.status == "visible" && scripture_circle_post.ward_id == ward_id

      errors.add(:scripture_circle_post, :invalid)
    end

    def voter_belongs_to_ward
      return if voter_person.blank? || ward.blank?
      errors.add(:voter_person, :invalid) unless voter_person.ward_id == ward_id
    end

    def not_author_vote
      return if scripture_circle_post.blank? || voter_person_id.blank?
      errors.add(:voter_person, :invalid) if scripture_circle_post.person_id == voter_person_id
    end
end
