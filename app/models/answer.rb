class Answer < ApplicationRecord
  belongs_to :round_run
  belongs_to :team
  belongs_to :player

  validates :body, presence: true, length: { maximum: 140 }
end
