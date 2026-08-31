class ScriptureCircleModerationReport < ApplicationRecord
  REASON_KEYS = ScriptureCircleModerationProposal::REASON_KEYS

  belongs_to :scripture_circle_post
  belongs_to :ward
  belongs_to :reporter_person, class_name: "Person", inverse_of: :scripture_circle_moderation_reports

  validates :reason_key, presence: true, inclusion: { in: REASON_KEYS }
  validates :reason_details, length: { maximum: 240 }, allow_blank: true
  validates :reporter_person_id, uniqueness: { scope: :scripture_circle_post_id }
  validate :same_ward
  validate :reporter_is_not_author, on: :create

  before_validation :normalize_details

  private

    def normalize_details
      self.reason_details = reason_details.to_s.squish.presence
    end

    def same_ward
      return if scripture_circle_post.blank? || reporter_person.blank?

      valid = scripture_circle_post.ward_id == ward_id && reporter_person.ward_id == ward_id
      errors.add(:ward, :invalid) unless valid
    end

    def reporter_is_not_author
      return if scripture_circle_post.blank? || reporter_person.blank?

      errors.add(:reporter_person, :invalid) if scripture_circle_post.person_id == reporter_person_id
    end
end
