class Person < ApplicationRecord
  NAME_MAX = 24
  YEAR_MIN = 1000
  CONTROL_CHARACTER_PATTERN = /[[:cntrl:]]/.freeze

  belongs_to :ward, optional: true
  belongs_to :last_ward_team, class_name: "WardTeam", optional: true
  has_many :person_devices, dependent: :destroy
  has_many :players, dependent: :nullify
  has_many :quiz_runs, dependent: :nullify
  has_many :study_runs, dependent: :nullify
  has_many :reading_progresses, dependent: :destroy
  has_many :scripture_chapter_reads, dependent: :nullify
  has_many :scripture_highlights, dependent: :destroy
  has_many :viral_events, dependent: :nullify
  has_many :sent_duel_invitations,
    class_name: "DuelInvitation",
    foreign_key: :challenger_person_id,
    dependent: :restrict_with_exception,
    inverse_of: :challenger_person
  has_many :received_duel_invitations,
    class_name: "DuelInvitation",
    foreign_key: :recipient_person_id,
    dependent: :nullify,
    inverse_of: :recipient_person
  has_many :web_push_subscriptions, dependent: :destroy
  has_one :notification_preference, dependent: :destroy
  has_many :notification_deliveries, dependent: :destroy

  validates :given_name, :given_name_key, :avatar_key, :locale, presence: true
  validates :given_name, length: { maximum: NAME_MAX }, format: { without: CONTROL_CHARACTER_PATTERN }
  validates :family_name,
    length: { maximum: NAME_MAX },
    format: { without: CONTROL_CHARACTER_PATTERN },
    allow_blank: true
  validates :avatar_key, inclusion: { in: ->(_) { Player::AVATARS } }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :favorite_year, numericality: { only_integer: true, greater_than_or_equal_to: YEAR_MIN }, allow_nil: true
  validate :favorite_year_not_future
  validate :last_ward_team_belongs_to_ward

  before_validation :normalize_profile_fields
  before_validation :reset_last_ward_team_after_ward_change
  before_validation :assign_name_keys

  scope :in_ward, ->(ward) { where(ward:) }
  scope :named, ->(value) { where(given_name_key: name_key(value)) }

  def self.name_key(value)
    I18n.transliterate(value.to_s.strip).downcase.gsub(/[^a-z0-9]/, "")
  end

  def self.year_range
    YEAR_MIN..Time.current.year
  end

  def self.valid_year?(value)
    raw = value.to_s.strip
    return false unless raw.match?(/\A\d{4}\z/)

    year_range.cover?(raw.to_i)
  end

  def self.on_device(device_token, ward)
    return none if device_token.blank? || ward.blank?

    joins(:person_devices).where(ward:).where(person_devices: { device_token: }).distinct.order(:given_name)
  end

  def self.on_device_anywhere(device_token)
    return none if device_token.blank?

    joins(:person_devices).where(person_devices: { device_token: }).distinct.order(:given_name)
  end

  def display_name
    family_name.present? ? "#{given_name} #{family_name}" : given_name
  end

  def card_caption(show_year: false)
    parts = [ given_name ]
    parts << family_name if family_name.present?
    parts << favorite_year.to_s if show_year
    parts.compact.join(" · ")
  end

  def profile_stamp
    I18n.l(created_at, format: "%d/%m/%Y %H:%M")
  end

  def notification_settings
    notification_preference || build_notification_preference
  end

  private

    def normalize_profile_fields
      self.given_name = normalize_name(given_name)
      self.family_name = normalize_name(family_name).presence
      self.avatar_key = avatar_key.to_s.strip if avatar_key
      self.locale = locale.to_s.strip if locale
    end

    def normalize_name(value)
      value.to_s.strip.gsub(/ {2,}/, " ")
    end

    def reset_last_ward_team_after_ward_change
      return unless will_save_change_to_ward_id?
      return if last_ward_team.blank? || last_ward_team.ward_id == ward_id

      self.last_ward_team = nil
    end

    def assign_name_keys
      self.given_name_key = self.class.name_key(given_name)
      self.family_name_key = self.class.name_key(family_name)
    end

    def favorite_year_not_future
      return if favorite_year.blank?

      errors.add(:favorite_year, :future) if favorite_year > Time.current.year
    end

    def last_ward_team_belongs_to_ward
      return if last_ward_team.blank?
      return if ward.present? && last_ward_team.ward_id == ward.id

      errors.add(:last_ward_team, :invalid)
    end
end
