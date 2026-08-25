class Ward < ApplicationRecord
  FEATURED_CITY = "benidorm"
  FEATURED_CODE = "RAMA"
  COUNTRY_CODES = %w[ES PT FR GB US BR MX AR CL PE CO UY IT DE BE CH CA AU NZ PH IE NL].freeze

  has_many :people, dependent: :destroy
  has_many :ward_teams, dependent: :destroy
  has_many :game_sessions, dependent: :restrict_with_exception
  has_many :person_devices, through: :people

  scope :listed, -> { where(listed: true) }

  validates :name, :code, :presenter_token_digest, presence: true
  validates :code, uniqueness: true
  validates :name, length: { maximum: 48 }
  validates :emblem, inclusion: { in: Team::EMBLEMS.keys }
  validates :country_code, inclusion: { in: COUNTRY_CODES }, allow_blank: true
  validates :chapel_name, :chapel_address, :city, :region, :postal_code, length: { maximum: 80 }, allow_blank: true

  attr_accessor :presenter_token

  def self.normalize_code(value)
    GameSession.normalize_code(value)
  end

  def presenter_token_matches?(token)
    digest = GameSession.digest_token(token)
    ActiveSupport::SecurityUtils.secure_compare(presenter_token_digest, digest)
  end

  def live_night
    if game_sessions.loaded?
      game_sessions.select(&:live?).max_by(&:updated_at)
    else
      game_sessions.live.order(updated_at: :desc).first
    end
  end

  def nights_count
    game_sessions.loaded? ? game_sessions.size : game_sessions.count
  end

  def maps_query
    [ chapel_address, postal_code, city, region ].compact_blank.join(", ")
  end

  def maps_url
    return if maps_query.blank?

    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(maps_query)}"
  end

  def featured?
    city.to_s.downcase == FEATURED_CITY || code == FEATURED_CODE
  end
end
