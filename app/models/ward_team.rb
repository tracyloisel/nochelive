class WardTeam < ApplicationRecord
  belongs_to :ward
  has_many :people, foreign_key: :last_ward_team_id, dependent: :nullify
  has_many :teams, dependent: :nullify

  validates :name, :emblem, :season_rank_key, presence: true
  validates :emblem, inclusion: { in: Team::EMBLEMS.keys }
  validates :name, uniqueness: { scope: :ward_id }
  validates :season_xp, numericality: { greater_than_or_equal_to: 0 }

  SEASON_RANKS = Team::RANKS.map { |threshold, key, label| [ threshold * 4, key, label ] }.freeze

  def season_rank_label
    (SEASON_RANKS.find { |_, key, _| key == season_rank_key } || SEASON_RANKS.first).last
  end

  def season_rank_index(key = season_rank_key)
    SEASON_RANKS.index { |_, rank_key, _| rank_key == key } || 0
  end

  def apply_night_xp!(xp)
    total = season_xp + xp.to_i
    previous = season_rank_key
    key = SEASON_RANKS.reverse.find { |threshold, _, _| total >= threshold }&.second || "novicio"
    update!(season_xp: total, season_rank_key: key)
    key != previous ? Team.rank_label_for(key) : nil
  end
end
