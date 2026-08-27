class ReadingProgress < ApplicationRecord
  STATUSES = %w[opened completed].freeze

  belongs_to :person
  belongs_to :study_unit

  validates :reference, :status, presence: true
  validates :reference, uniqueness: { scope: [ :person_id, :study_unit_id ] }
  validates :status, inclusion: { in: STATUSES }
end
