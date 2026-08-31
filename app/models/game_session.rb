class GameSession < ApplicationRecord
  STATUSES = %w[scheduled lobby playing finished cancelled].freeze
  CODE_WORDS = %w[DAVID ELIAS SALOMON DANIEL RUT ESTHER JONAS CALEB NOEMI SARA].freeze
  CODE_CHARS = %w[A B C D E F G H J K M N P Q R S T U W X Y Z 2 3 4 5 6 7 8 9].freeze
  LOBBY_LEAD = 30.minutes
  DURATION = 1.hour

  belongs_to :ward
  has_many :teams, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :quiz_runs, dependent: :destroy
  has_many :live_events, dependent: :destroy

  validates :code, :status, :starts_at, :ends_at, presence: true
  validates :code, uniqueness: { conditions: -> { where.not(status: %w[finished cancelled]) } }
  validates :status, inclusion: { in: STATUSES }
  validate :quiz_pack_sequence_is_valid
  validate :ends_one_hour_after_start
  before_validation :normalize_schedule

  scope :active, -> { where.not(status: %w[finished cancelled]) }
  scope :live, -> { active }
  scope :finished, -> { where(status: "finished") }

  def self.generate_code
    SecureRandom.random_number(3).zero? ? CODE_WORDS.sample : Array.new(5) { CODE_CHARS.sample }.join
  end

  def self.digest_token(token) = Digest::SHA256.hexdigest(token.to_s)
  def self.normalize_code(value) = value.to_s.upcase.gsub(/[^A-Z0-9]/, "")

  def self.find_by_code(code)
    key = normalize_code(code)
    return if key.blank?

    active.where(code: key).order(id: :desc).first || where(code: key).order(id: :desc).first
  end

  def self.find_by_code!(code) = find_by_code(code) || raise(ActiveRecord::RecordNotFound)

  def quiz_packs = quiz_pack_ids.map { |pack_id| QuizDefinition.catalog.find_pack(pack_id) }
  def primary_quiz_pack = quiz_packs.first
  def lobby_at = starts_at - LOBBY_LEAD

  def phase(at: Time.current)
    return :cancelled if cancelled_at? || status == "cancelled"
    return :finished if closed_at? || at >= ends_at
    return :scheduled if at < lobby_at
    return :lobby if at < starts_at

    :playing
  end

  def scheduled? = phase == :scheduled
  def lobby? = phase == :lobby
  def playing? = phase == :playing
  def finished? = phase == :finished
  def cancelled? = phase == :cancelled
  def live? = !finished? && !cancelled?
  def open_for_registration? = !finished? && !cancelled?
  def open_for_team_selection? = %i[lobby playing].include?(phase)
  def playable? = playing?

  def current_quiz_position
    value = quiz_runs.maximum(:live_sequence_position).to_i
    value.zero? ? 1 : value.clamp(1, quiz_pack_ids.size)
  end

  def current_quiz_pack = quiz_packs[current_quiz_position - 1]
  def locale_stream(locale) = [ self, :live, Locale.cast(locale) ]
  def reconcile!(at: Time.current) = Nights::Reconcile.call(night: self, at:)
  def broadcast_state(event: nil) = Nights::Broadcast.call(night: self, event:)

  private

    def normalize_schedule
      self.ends_at = starts_at + DURATION if starts_at.present?
      self.status = phase(at: Time.current).to_s if starts_at.present? && ends_at.present? && status != "cancelled"
    end

    def quiz_pack_sequence_is_valid
      ids = quiz_pack_ids
      unless ids.is_a?(Array) && ids.present? && ids.all? { |id| id.is_a?(String) && id.present? }
        errors.add(:quiz_pack_ids, "must contain at least one quiz")
        return
      end

      errors.add(:quiz_pack_ids, "cannot contain duplicates") if ids.uniq.size != ids.size
      ids.each { |id| QuizDefinition.catalog.find_pack(id) }
    rescue QuizDefinition::Error => error
      errors.add(:quiz_pack_ids, error.message)
    end

    def ends_one_hour_after_start
      return unless starts_at && ends_at

      errors.add(:ends_at, "must be exactly one hour after starts_at") unless ends_at.to_i == (starts_at + DURATION).to_i
    end
end
