class StudyAnswer < ApplicationRecord
  belongs_to :study_run

  validates :question_key, :choice_key, presence: true
  validates :question_key, uniqueness: { scope: :study_run_id }
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
