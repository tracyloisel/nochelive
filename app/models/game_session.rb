class GameSession < ApplicationRecord
  STATUSES = %w[lobby playing paused finished].freeze
  CODE_WORDS = %w[DAVID ELIAS SALOMON DANIEL RUT ESTHER JONAS CALEB NOEMI SARA].freeze
  CODE_CHARS = %w[A B C D E F G H J K M N P Q R S T U W X Y Z 2 3 4 5 6 7 8 9].freeze

  belongs_to :ward
  has_many :teams, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :round_runs, -> { order(:position) }, dependent: :destroy
  has_many :score_events, dependent: :destroy
  has_many :missionaries, -> { order(:id) }, dependent: :destroy
  has_many :presenter_claims, dependent: :destroy
  has_many :presenter_blocks, dependent: :destroy
  has_many :audience_responses, through: :round_runs
  has_many :audience_reactions, through: :round_runs

  validates :code, :status, :theme_id, :theme_title, :presenter_token_digest, :starts_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :presenter_locale, inclusion: { in: Locale::AVAILABLE }
  validates :public_token, presence: true, uniqueness: true
  validates :broadcast_delay_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 30_000 }

  before_validation :assign_public_token, on: :create

  scope :live, -> { where.not(status: "finished") }
  scope :finished, -> { where(status: "finished") }

  attr_accessor :presenter_token

  def self.start!(theme_id: "reyes_y_profetas", ward: nil)
    Nights::Start.call(ward: ward || Ward.order(:id).first!, theme_id:)
  end

  def self.generate_code
    if SecureRandom.random_number(3).zero?
      CODE_WORDS.sample
    else
      Array.new(5) { CODE_CHARS.sample }.join
    end
  end

  def self.digest_token(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.normalize_code(value)
    value.to_s.upcase.gsub(/[^A-Z0-9]/, "")
  end

  def self.find_by_code(code)
    key = normalize_code(code)
    return if key.blank?

    live.where(code: key).order(id: :desc).first || where(code: key).order(id: :desc).first
  end

  def self.find_by_code!(code)
    find_by_code(code) || raise(ActiveRecord::RecordNotFound)
  end

  def definition
    @definition ||= GameDefinition.load(theme_file_id)
  end

  def theme_file_id
    theme_id == "kings_and_prophets" ? "reyes_y_profetas" : "reyes_y_profetas"
  end

  def presenter_token_matches?(token)
    digest = self.class.digest_token(token)
    ActiveSupport::SecurityUtils.secure_compare(presenter_token_digest, digest)
  end

  def presenter_held_by?(token)
    return false if presenter_device_digest.blank? || token.blank?

    ActiveSupport::SecurityUtils.secure_compare(presenter_device_digest, self.class.digest_token(token))
  end

  def pending_presenter_claim
    presenter_claims.pending.order(:id).first
  end

  def claim_stream(digest) = [ self, :presenter_claim, digest ]

  def current_round_run
    round_runs.where.not(phase: %w[pending completed]).first ||
      round_runs.where.not(phase: "completed").first
  end

  def lobby? = status == "lobby"
  def playing? = status == "playing"
  def paused? = status == "paused"
  def finished? = status == "finished"
  def live? = !finished?

  def start_playing!
    update!(status: "playing")
    return if round_runs.active.exists?

    round_runs.pending.first&.intro!
  end

  def pause! = update!(status: "paused")
  def resume! = update!(status: "playing")

  def finish!
    current_round_run&.complete! if current_round_run&.may_complete?
    update!(status: "finished")
  end

  def podium_teams
    teams.includes(:players).to_a.sort_by { |team| [ -team.cached_score, team.name.to_s ] }
  end

  def first_place_teams
    top = podium_teams.first
    return [] unless top

    podium_teams.select { |team| team.cached_score == top.cached_score }
  end

  def champion
    return if first_place_teams.size != 1

    first_place_teams.first
  end

  def scored_finale?
    teams.any? { |team| team.cached_score.to_i.positive? }
  end

  def tied_finale?
    first_place_teams.size > 1
  end

  def place_for(team)
    return unless team

    podium_teams.map(&:cached_score).uniq.index(team.cached_score)&.+(1)
  end

  def visual_podium
    top = podium_teams.first(3)
    case top.size
    when 3 then [ top[1], top[0], top[2] ]
    when 2 then [ top[1], top[0] ]
    else top
    end
  end

  def stream_name = [ self, :night ]
  def presenter_stream = [ self, :presenter ]
  def watch_stream = [ self, :watch ]
  def team_stream(team) = [ self, :team, team ]
  def player_stream(player) = [ self, :player, player ]
  def audience_stream = [ self, :audience ]

  def participants
    players.participants
  end

  def broadcast_state(pulse: nil)
    Nights::Broadcast.call(night: self, pulse: pulse)
  end

  private

    def assign_public_token
      self.public_token ||= SecureRandom.urlsafe_base64(18)
    end
end
