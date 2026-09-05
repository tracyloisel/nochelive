class StudyQuizVersion < ApplicationRecord
  STATUSES = %w[draft needs_review published retired].freeze

  belongs_to :study_unit
  has_many :study_runs, dependent: :restrict_with_exception

  before_validation :refresh_daily_discovery_content_digest, if: :daily_discoveries?

  validates :version, :status, :editorial_locale, :content, :content_digest, presence: true
  validates :version, uniqueness: { scope: :study_unit_id }
  validates :status, inclusion: { in: STATUSES }
  validate :learning_content
  validate :published_daily_discovery_content
  validate :immutable_published_daily_discoveries, on: :update

  def questions
    Array(content["questions"])
  end

  def expedition
    content["expedition"].is_a?(Hash) ? content["expedition"] : {}
  end

  def expedition?
    expedition_pack_ids.any?
  end

  def expedition_pack_ids
    Array(expedition["pack_ids"]).filter_map { |pack_id| pack_id.to_s.presence }.uniq
  end

  def daily_discoveries
    value = content["daily_discoveries"] if content.is_a?(Hash)
    value.is_a?(Array) ? value : []
  end

  def daily_discoveries?
    content.is_a?(Hash) && content.key?("daily_discoveries")
  end

  def daily_discovery_time_zone
    zones = daily_discoveries.filter_map { |row| row["timezone"].to_s.presence if row.is_a?(Hash) }.uniq
    zones.first if zones.one? && Time.find_zone(zones.first)
  end

  def calculated_content_digest
    self.class.content_digest_for(content)
  end

  def content_digest_current?
    content_digest.present? && ActiveSupport::SecurityUtils.secure_compare(content_digest, calculated_content_digest)
  end

  def daily_discovery_publication_errors
    Studies::DailyDiscoveryContract.call(
      rows: content.is_a?(Hash) ? content["daily_discoveries"] : nil,
      expedition_pack_ids:,
      starts_on: study_unit&.starts_on,
      ends_on: study_unit&.ends_on
    )
  end

  def daily_discoveries_publishable?
    daily_discoveries? && daily_discovery_publication_errors.empty?
  end

  def self.content_digest_for(payload)
    Digest::SHA256.hexdigest(JSON.generate(canonical_content(payload)))
  end

  def self.canonical_content(value)
    case value
    when Hash
      value.to_h.sort_by { |key, _item| key.to_s }.to_h do |key, item|
        [ key.to_s, canonical_content(item) ]
      end
    when Array
      value.map { |item| canonical_content(item) }
    else
      value
    end
  end
  private_class_method :canonical_content

  def readings(locale = I18n.locale)
    Array(content["readings"]).filter_map do |reading|
      next unless reading["study"].present?

      reading.merge("label" => reading.dig("labels", locale.to_s))
    end
  end

  def reading_for(question, locale = I18n.locale)
    chapter = question["scripture_ref"].to_s[/\d+/]
    readings(locale).find { |reading| reading["study"].to_s.end_with?("/#{chapter}") }
  end

  def self.known_scripture_study?(study)
    where(status: "published").pluck(:content).any? do |payload|
      Array(payload["readings"]).any? { |reading| reading["study"] == study }
    end
  end

  def question_at(position)
    questions.fetch(position.to_i - 1)
  end

  def localized_question(position, locale = I18n.locale)
    question = question_at(position)
    localized = question.dig("locales", locale.to_s) || question.dig("locales", "fr") || {}
    question.merge(localized)
  end

  private

    def learning_content
      if expedition?
        errors.add(:content, "expedition cannot embed a second quiz set") if questions.any?
        # Archived packs remain valid historical references. They are absent
        # from the playable catalog, but published and retired expedition
        # versions must still be loadable, reproducible and testable.
        known_pack_ids = QuizDefinition.catalog.all_packs.map(&:id)
        unknown = expedition_pack_ids.reject { |pack_id| known_pack_ids.include?(pack_id) }
        errors.add(:content, "contains unknown expedition packs: #{unknown.join(', ')}") if unknown.any?
      elsif questions.size != 10
        errors.add(:content, "must contain 10 questions")
      end
    end

    def published_daily_discovery_content
      return unless status == "published" && daily_discoveries?

      daily_discovery_publication_errors.each { |issue| errors.add(:content, issue) }
    end

    def refresh_daily_discovery_content_digest
      self.content_digest = calculated_content_digest
    end

    def immutable_published_daily_discoveries
      return unless status_in_database == "published" && daily_discoveries?
      return unless will_save_change_to_content? || will_save_change_to_content_digest?

      errors.add(:content, "published daily discoveries are immutable; publish a new version")
    end
end
