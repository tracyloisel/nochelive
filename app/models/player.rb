class Player < ApplicationRecord
  ROLES = %w[participant spectator presenter].freeze
  LOCATIONS = %w[room remote].freeze
  AVATARS = %w[
    delfin ballena tortuga
    aguila loro colibri
    elefante jirafa cebra
    perro gato oveja
  ].freeze

  belongs_to :game_session
  belongs_to :person, optional: true
  has_one :team_membership, dependent: :destroy
  has_one :team, through: :team_membership
  has_many :buzzes, class_name: "Buzz", dependent: :nullify
  has_many :answers, dependent: :nullify
  has_many :ballots, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :received_cheers, class_name: "Cheer", foreign_key: :to_player_id, dependent: :destroy

  validates :name, :client_token, :role, :avatar_key, :locale, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :location, inclusion: { in: LOCATIONS }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :avatar_key, inclusion: { in: AVATARS }
  validates :name, length: { minimum: 1, maximum: 24 }
  before_validation :assign_avatar_key

  LIVE_WINDOW = 25.seconds
  scope :participants, -> { where(role: "participant") }
  scope :live, -> { where(last_seen_at: LIVE_WINDOW.ago..) }

  def participant? = role == "participant"
  def spectator? = role == "spectator"
  def remote? = location == "remote"
  def live?
    last_seen_at.present? && last_seen_at >= LIVE_WINDOW.ago
  end

  private

    def assign_avatar_key
      self.avatar_key = person&.avatar_key.presence || "delfin" if avatar_key.blank?
    end
end
