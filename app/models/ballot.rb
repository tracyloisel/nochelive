class Ballot < ApplicationRecord
  belongs_to :round_run
  belongs_to :team
  belongs_to :player
  belongs_to :choice_team, class_name: "Team"

  validate :choice_is_another_team

  private

  def choice_is_another_team
    return if choice_team_id.blank? || team_id.blank?
    return if choice_team_id != team_id

    errors.add(:choice_team, "cannot be your team")
  end
end
