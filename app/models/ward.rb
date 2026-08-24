class Ward < ApplicationRecord
  has_many :people, dependent: :destroy
  has_many :ward_teams, dependent: :destroy
  has_many :game_sessions, dependent: :restrict_with_exception
  has_many :person_devices, through: :people

  validates :name, :code, :presenter_token_digest, presence: true
  validates :code, uniqueness: true
  validates :name, length: { maximum: 48 }

  attr_accessor :presenter_token

  def self.normalize_code(value)
    GameSession.normalize_code(value)
  end

  def presenter_token_matches?(token)
    digest = GameSession.digest_token(token)
    ActiveSupport::SecurityUtils.secure_compare(presenter_token_digest, digest)
  end
end
