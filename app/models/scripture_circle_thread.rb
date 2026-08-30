class ScriptureCircleThread < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :ward
  has_many :scripture_circle_posts, dependent: :destroy

  validates :reference, :status, presence: true
  validates :reference, uniqueness: { scope: :ward_id }
  validates :status, inclusion: { in: STATUSES }
  validate :known_reference

  private

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end
end
