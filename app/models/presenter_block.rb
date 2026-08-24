class PresenterBlock < ApplicationRecord
  belongs_to :game_session

  validates :device_digest, presence: true, uniqueness: { scope: :game_session_id }
end
