class AudienceReaction < ApplicationRecord
  MARKS = %w[applause heart crown].freeze

  belongs_to :round_run

  validates :audience_digest, :mark, presence: true
  validates :mark, inclusion: { in: MARKS }

  scope :recent, -> { where(created_at: 90.seconds.ago..) }
end
