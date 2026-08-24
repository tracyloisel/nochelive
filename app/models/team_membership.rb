class TeamMembership < ApplicationRecord
  belongs_to :player
  belongs_to :team

  validates :player_id, uniqueness: true
  validate :same_session

  private

  def same_session
    return if player.blank? || team.blank?
    errors.add(:team, "must belong to the same night") unless player.game_session_id == team.game_session_id
  end
end
