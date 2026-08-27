class QuizAnswer < ApplicationRecord
  belongs_to :quiz_run

  validates :device_digest, :pack_id, :question_id, presence: true
  validates :question_id, uniqueness: { scope: :quiz_run_id }
  validates :duration_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
