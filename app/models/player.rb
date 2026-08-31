class Player < ApplicationRecord
  AVATARS = %w[delfin ballena tortuga aguila loro colibri elefante jirafa cebra perro gato oveja].freeze

  belongs_to :game_session
  belongs_to :person, optional: true
  has_one :team_membership, dependent: :destroy
  has_one :team, through: :team_membership
  has_many :quiz_runs, dependent: :nullify

  validates :name, :client_token, :avatar_key, :locale, presence: true
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :avatar_key, inclusion: { in: AVATARS }
  validates :name, length: { minimum: 1, maximum: 24 }
  before_validation :assign_live_defaults


  private

    def assign_live_defaults
      self.avatar_key = person&.avatar_key.presence || "delfin" if avatar_key.blank?
    end
end
