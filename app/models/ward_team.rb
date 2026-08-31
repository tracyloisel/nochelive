class WardTeam < ApplicationRecord
  NAME_MAX = 80

  belongs_to :ward
  has_many :people, foreign_key: :last_ward_team_id, dependent: :nullify
  has_many :teams, dependent: :nullify

  validates :name, :emblem, presence: true
  validates :name, length: { maximum: NAME_MAX }
  validates :emblem, inclusion: { in: Team::EMBLEMS.keys }
  validates :name, uniqueness: { scope: :ward_id }
end
