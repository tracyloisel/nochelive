class Ward < ApplicationRecord
  def sunday_schedule
    hours = locator_payload&.dig("hours")
    return [] unless hours.is_a?(Hash)

    sunday = Array(hours["days"]).find { |day| day.dig("day", "code") == "SUNDAY" }
    range = Array(sunday&.dig("hours", "ranges")).first
    start_time = hours.dig("primary", "hour", "code").presence || range&.dig("start", "code").presence
    finish_time = range&.dig("finish", "code").presence

    if start_time.blank?
      match = hours["code"].to_s.match(/\bSu\s+(\d{1,2}:\d{2})(?:-(\d{1,2}:\d{2}))?/)
      start_time = match&.[](1)
      finish_time ||= match&.[](2)
    end

    [
      ({ "label_key" => "sacrament_meeting", "time" => short_time(start_time) } if start_time.present?),
      ({ "label_key" => "sunday_meetings", "time" => "#{short_time(start_time)}–#{short_time(finish_time)}" } if start_time.present? && finish_time.present?)
    ].compact
  end

  FEATURED_CITY = "benidorm"
  FEATURED_CODE = "RAMA"
  UNIT_KINDS = %w[ward branch].freeze
  SCRIPTURE_CIRCLE_MODES = %w[disabled read_only active].freeze
  NAME_MAX = 120

  has_many :people, dependent: :destroy
  has_many :ward_teams, dependent: :destroy
  has_many :game_sessions, dependent: :restrict_with_exception
  has_many :ward_events, dependent: :destroy
  has_many :ward_event_audits, dependent: :destroy
  has_many :person_devices, through: :people
  has_many :scripture_circle_threads, dependent: :destroy
  has_many :scripture_circle_posts, dependent: :destroy
  has_many :scripture_circle_conversation_votes, dependent: :destroy
  has_many :scripture_circle_post_votes, dependent: :destroy
  has_many :scripture_circle_moderation_reports, dependent: :destroy

  scope :listed, -> { where(listed: true) }

  validates :name, :code, :admin_token_digest, presence: true
  validates :code, uniqueness: true
  validates :church_unit_id, uniqueness: true, allow_nil: true
  validates :name, length: { maximum: NAME_MAX }
  validates :emblem, inclusion: { in: Team::EMBLEMS.keys }
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
  validates :unit_kind, inclusion: { in: UNIT_KINDS }, allow_blank: true
  validates :scripture_circle_mode, inclusion: { in: SCRIPTURE_CIRCLE_MODES }
  validates :chapel_name, :chapel_address, :city, :region, :postal_code, :stake_name, :stake_unit_id, :country_name, length: { maximum: 80 }, allow_blank: true

  attr_accessor :admin_token

  private

    def short_time(value)
      value.to_s.sub(/:00\z/, "").sub(/\A(\d):/, '0\\1:')
    end

  public

  def self.normalize_code(value)
    GameSession.normalize_code(value)
  end

  def self.generate_import_code
    Array.new(5) { GameSession::CODE_CHARS.sample }.join
  end

  def admin_token_matches?(token)
    digest = GameSession.digest_token(token)
    ActiveSupport::SecurityUtils.secure_compare(admin_token_digest, digest)
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

  def scripture_circle_active? = scripture_circle_mode == "active"
  def scripture_circle_readable? = scripture_circle_mode.in?(%w[read_only active])
end
