class StreetDuel < ApplicationRecord
  STATUSES = %w[active one_scored resolved expired archived].freeze
  ACTIVE = %w[active one_scored].freeze

  belongs_to :challenger_person, class_name: "Person"
  belongs_to :opponent_person, class_name: "Person"
  belongs_to :challenger_run, class_name: "QuizRun", optional: true
  belongs_to :opponent_run, class_name: "QuizRun", optional: true
  belongs_to :rematch_of, class_name: "StreetDuel", optional: true
  belongs_to :origin_invitation, class_name: "DuelInvitation"
  has_many :duel_invitations, dependent: :nullify
  has_many :rematches, class_name: "StreetDuel", foreign_key: :rematch_of_id, dependent: :nullify, inverse_of: :rematch_of
  has_many :viral_events, dependent: :destroy

  validates :status, :expires_at, :pair_low_person_id, :pair_high_person_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :people_are_distinct

  before_validation :assign_pair

  scope :active, -> { where(status: ACTIVE) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }

  def one_scored? = status == "one_scored"
  def resolved? = status == "resolved"
  def expired_status? = status == "expired"
  def archived? = status == "archived"
  def expired? = expired_status? || expires_at <= Time.current
  def active? = ACTIVE.include?(status)
  def rematch? = rematch_of_id.present?

  def includes_person?(person) = person && [ challenger_person_id, opponent_person_id ].include?(person.id)

  def role_for(person)
    return :challenger if person&.id == challenger_person_id
    return :opponent if person&.id == opponent_person_id

    :other
  end

  def other_person_for(person)
    case role_for(person)
    when :challenger then opponent_person
    when :opponent then challenger_person
    end
  end

  def score_for(person)
    case role_for(person)
    when :challenger then challenger_score
    when :opponent then opponent_score
    end
  end

  def other_score_for(person)
    case role_for(person)
    when :challenger then opponent_score
    when :opponent then challenger_score
    end
  end

  def run_for(person)
    case role_for(person)
    when :challenger then challenger_run
    when :opponent then opponent_run
    end
  end

  def result_seen_at_for(person)
    case role_for(person)
    when :challenger then challenger_result_seen_at
    when :opponent then opponent_result_seen_at
    end
  end

  def winner_person
    return unless resolved? && challenger_score && opponent_score

    if challenger_score > opponent_score
      challenger_person
    elsif opponent_score > challenger_score
      opponent_person
    end
  end

  def loser_person
    winner = winner_person
    return unless winner

    winner.id == challenger_person_id ? opponent_person : challenger_person
  end

  private

    def assign_pair
      ids = [ challenger_person_id, opponent_person_id ].compact.sort
      self.pair_low_person_id, self.pair_high_person_id = ids if ids.size == 2
    end

    def people_are_distinct
      return if challenger_person_id.blank? || opponent_person_id.blank?
      return unless challenger_person_id == opponent_person_id

      errors.add(:opponent_person, :invalid)
    end
end
