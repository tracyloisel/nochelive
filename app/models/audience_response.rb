class AudienceResponse < ApplicationRecord
  belongs_to :round_run

  validates :audience_digest, :choice, :answered_at, presence: true
  validates :choice, length: { maximum: 80 }

  scope :ordered, -> { order(:answered_at, :id) }

  def correct?
    choice.to_s == round_run.definition.correct_choice.to_s
  end
end
