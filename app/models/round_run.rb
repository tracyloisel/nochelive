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
  def accepting_buzzes? = open?
  def accepting_answers?
    return open? if definition.choice? || definition.mime? || definition.taboo? || definition.scavenger? || definition.ordering? || definition.category?
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
