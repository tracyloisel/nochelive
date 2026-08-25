class RoundRun < ApplicationRecord
  PHASES = %w[pending intro open locked answering revealed completed].freeze
  TRANSITIONS = {
    "pending" => %w[intro],
    "intro" => %w[open completed],
    "open" => %w[locked answering revealed completed],
    "locked" => %w[answering revealed completed],
    "answering" => %w[revealed completed],
    "revealed" => %w[completed],
    "completed" => []
  }.freeze

  belongs_to :game_session
  has_many :buzzes, -> { order(:position) }, class_name: "Buzz", dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :score_events, dependent: :destroy
  has_many :tap_runs, dependent: :destroy
  has_many :pose_holds, dependent: :destroy
  has_many :ballots, dependent: :destroy
  has_many :cheers, dependent: :destroy

  validates :yaml_round_id, :position, :phase, presence: true
  validates :phase, inclusion: { in: PHASES }

  scope :pending, -> { where(phase: "pending") }
  scope :active, -> { where.not(phase: %w[pending completed]) }

  def definition
    @definition ||= game_session.definition.find_round(yaml_round_id)
  end

  def pending? = phase == "pending"
  def intro? = phase == "intro"
  def open? = phase == "open"
  def locked? = phase == "locked"
  def answering? = phase == "answering"
  def revealed? = phase == "revealed"
  def completed? = phase == "completed"
  def live? = phase.in?(%w[intro open locked answering revealed])

  def current_layer
    return if layer_index.to_i <= 0

    definition.layers[layer_index - 1]
  end

  def last_layer?
    definition.layered_finale? && definition.layers.any? && layer_index >= definition.layers.size
  end

  def burger_assembled?
    definition.layered_finale? && last_layer? && intro?
  end

  def anyone_correct?
    score_events.exists?(kind: "correct")
  end

  def chapel_correct?
    ids = room_team_ids
    ids.any? && score_events.exists?(team_id: ids, kind: "correct")
  end

  def room_team_ids
    TeamMembership.where(player_id: game_session.players.participants.where(location: "room").select(:id)).distinct.pluck(:team_id)
  end

  def finale_steal_open?
    return false unless definition.layered_finale?
    return false unless last_layer?
    return false unless phase.in?(%w[open locked answering])
    return false if anyone_correct?

    ids = room_team_ids
    return true if ids.empty?

    return true if locked?

    room_incorrect = score_events.exists?(team_id: ids, kind: "incorrect")
    return false unless room_incorrect

    buzzes.none? { |buzz| ids.include?(buzz.team_id) && !scored?(buzz.team) }
  end

  def accepting_buzzes?
    return false unless open?
    return last_layer? if definition.layered_finale?

    true
  end

  def accepting_answers?(player: nil)
    return open? if definition.choice? || definition.mime? || definition.taboo? || definition.scavenger? || definition.ordering? || definition.category?
    if definition.layered_finale?
      return false unless last_layer?
      if player&.remote?
        return finale_steal_open? && phase.in?(%w[open locked answering])
      end

      return phase.in?(%w[open locked answering]) && answering_team.present?
    end
    return phase.in?(%w[open locked answering]) if definition.buzzer? && player&.remote?

    phase.in?(%w[locked answering])
  end
  def accepting_taps? = open? && (definition.rapid_tap? || definition.physical?)

  def timed?
    opened_at.present? && definition.duration.to_i.positive? && phase.in?(%w[open locked answering])
  end

  def ends_at
    return unless opened_at && definition.duration.to_i.positive?

    opened_at + definition.duration.seconds
  end

  def seconds_left
    return 0 unless timed? && ends_at

    [(ends_at - Time.current).ceil, 0].max
  end

  def intro!
    return if intro?

    transit!("intro")
  end

  def open!
    transit!("open", opened_at: Time.current)
  end

  def lock!
    transit!("locked", locked_at: Time.current)
  end

  def begin_answering!
    transit!("answering")
  end

  def reveal!
    transit!("revealed", revealed_at: Time.current)
  end

  def complete!
    transit!("completed")
  end

  def may_complete?
    TRANSITIONS[phase]&.include?("completed")
  end

  def answering_team
    return unless definition.buzzer?

    buzzes.includes(:team).find { |buzz| !scored?(buzz.team) }&.team
  end

  def first_buzz = buzzes.find_by(position: 1)

  def scored?(team)
    score_events.exists?(team: team, kind: %w[correct incorrect])
  end

  private

  def transit!(next_phase, extras = {})
    allowed = TRANSITIONS.fetch(phase)
    raise "Cannot move #{yaml_round_id} from #{phase} to #{next_phase}" unless allowed.include?(next_phase)
    update!({ phase: next_phase }.merge(extras))
  end
end
