class ScriptureCirclePostRevision < ApplicationRecord
  CHANGE_KINDS = %w[created edited anonymity_changed vote_snapshot author_deleted].freeze

  belongs_to :scripture_circle_post
  belongs_to :editor_person, class_name: "Person", optional: true
  belongs_to :ward

  validates :revision_number, numericality: { only_integer: true, greater_than: 0 }
  validates :revision_number, uniqueness: { scope: :scripture_circle_post_id }
  validates :body, :change_kind, :content_digest, presence: true
  validates :body, length: { maximum: ScriptureCirclePost::MAX_BODY_LENGTH }
  validates :anonymous, inclusion: { in: [ true, false ] }
  validates :author_visibility, inclusion: { in: ScriptureCirclePost::AUTHOR_VISIBILITIES }
  validates :change_kind, inclusion: { in: CHANGE_KINDS }
  validate :same_ward
  validate :anonymous_visibility_matches_post

  private

    def same_ward
      return if scripture_circle_post.blank? || scripture_circle_post.ward_id == ward_id

      errors.add(:ward, :invalid)
    end

    def anonymous_visibility_matches_post
      return unless author_visibility == "anonymous_to_ward"
      return if scripture_circle_post&.question_root?

      errors.add(:author_visibility, :invalid)
    end
end
