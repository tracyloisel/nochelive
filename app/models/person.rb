class Person < ApplicationRecord
  YEAR_MIN = 1000

  belongs_to :ward
  belongs_to :last_ward_team, class_name: "WardTeam", optional: true
  has_many :person_devices, dependent: :destroy
  has_many :players, dependent: :nullify

  validates :given_name, :given_name_key, :avatar_key, :favorite_year, presence: true
  validates :given_name, length: { minimum: 1, maximum: 24 }
  validates :family_name, length: { maximum: 24 }, allow_blank: true
  validates :avatar_key, inclusion: { in: ->(_) { Player::AVATARS } }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :favorite_year, numericality: { only_integer: true, greater_than_or_equal_to: YEAR_MIN }
  validate :favorite_year_not_future
  validates :favorite_year, uniqueness: { scope: [ :ward_id, :given_name_key, :family_name_key, :avatar_key ] }

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

  def display_name
    family_name.present? ? "#{given_name} #{family_name}" : given_name
  end

  def card_caption(show_year: false)
    parts = [ given_name ]
    parts << family_name if family_name.present?
    parts << favorite_year.to_s if show_year
    parts.compact.join(" · ")
  end

  private

    def assign_name_keys
      self.given_name_key = self.class.name_key(given_name)
      self.family_name_key = self.class.name_key(family_name)
    end

    def favorite_year_not_future
      return if favorite_year.blank?

      errors.add(:favorite_year, :future) unless self.class.year_range.cover?(favorite_year)
    end
end
