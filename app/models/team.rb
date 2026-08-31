class Team < ApplicationRecord
  EMBLEMS = {
    "leon" => "León", "fuego" => "Fuego", "paloma" => "Paloma",
    "corona" => "Corona", "ola" => "Ola", "estrella" => "Estrella"
  }.freeze
  RANKS = [
    [ 0, "novicio", "Novicio" ], [ 25, "explorador", "Explorador" ],
    [ 60, "guerrero", "Guerrero" ], [ 110, "consejero", "Consejero" ],
    [ 180, "profeta", "Profeta" ], [ 260, "leyenda", "Leyenda" ]
  ].freeze

  belongs_to :game_session
  belongs_to :ward_team
  has_many :team_memberships, dependent: :destroy
  has_many :players, through: :team_memberships
  has_many :quiz_runs, dependent: :nullify

  validates :name, :emblem, presence: true
  validates :emblem, inclusion: { in: EMBLEMS.keys }
  validates :name, uniqueness: { scope: :game_session_id }
  validates :ward_team_id, uniqueness: { scope: :game_session_id }

  def emblem_label = EMBLEMS[emblem]
end
