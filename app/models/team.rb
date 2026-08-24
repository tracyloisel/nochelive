class Team < ApplicationRecord
  EMBLEMS = {
    "leon" => "León",
    "fuego" => "Fuego",
    "paloma" => "Paloma",
    "corona" => "Corona",
    "ola" => "Ola",
    "estrella" => "Estrella"
  }.freeze

  RANKS = [
    [ 0, "novicio", "Novicio" ],
    [ 25, "explorador", "Explorador" ],
    [ 60, "guerrero", "Guerrero" ],
    [ 110, "consejero", "Consejero" ],
    [ 180, "profeta", "Profeta" ],
    [ 260, "leyenda", "Leyenda" ]
  ].freeze

  belongs_to :game_session
  belongs_to :ward_team, optional: true
  has_many :team_memberships, dependent: :destroy
  has_many :players, through: :team_memberships
  has_many :score_events, dependent: :destroy
  has_many :reward_grants, dependent: :destroy
  has_many :buzzes, class_name: "Buzz", dependent: :destroy
  has_many :ballots, dependent: :destroy
  has_many :received_ballots, class_name: "Ballot", foreign_key: :choice_team_id
  has_many :answers, dependent: :destroy
  has_many :tap_runs, dependent: :destroy
  has_many :pose_holds, dependent: :destroy

  validates :name, :emblem, presence: true
  validates :emblem, inclusion: { in: EMBLEMS.keys }
  validates :name, uniqueness: { scope: :game_session_id }

  def emblem_label = EMBLEMS[emblem]
  def rank_label = (RANKS.find { |_, key, _| key == rank_key } || RANKS.first).last

  def next_rank
    RANKS.find { |threshold, _, _| xp < threshold }
  end

  def xp_progress
    current = RANKS.reverse.find { |threshold, _, _| xp >= threshold } || RANKS.first
    nxt = next_rank
    return 100 unless nxt

    span = nxt[0] - current[0]
    return 100 if span <= 0

    (((xp - current[0]) * 100) / span).clamp(0, 100)
  end

  def next_rank_label
    next_rank&.last || "Leyenda"
  end

  def rey?
    next_correct_doubled?
  end

  def recalculate_progress!
    Ranks::Advance.call(team: self)
  end

  def self.rank_label_for(key)
    (RANKS.find { |_, rank_key, _| rank_key == key } || RANKS.first).last
  end

  def rank_index(key)
    RANKS.index { |_, rank_key, _| rank_key == key } || 0
  end

  def ready_chest
    reward_grants.find_by(state: "ready")
  end

  def opened_rewards
    reward_grants.where(state: "opened")
  end

end
