class Missionary < ApplicationRecord
  belongs_to :game_session

  validates :name, presence: true, length: { minimum: 1, maximum: 32 }
end
