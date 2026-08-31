class StudyQuizVersion < ApplicationRecord
  STATUSES = %w[draft needs_review published retired].freeze
  DAILY_DISCOVERY_KINDS = %w[discovery contemplation].freeze
  DAILY_DISCOVERY_STATUSES = %w[approved].freeze
  DAILY_DISCOVERY_COPY_FIELDS = %w[eyebrow title setup question cta_label].freeze
  DAILY_DISCOVERY_MOTIONS = %w[still ambient].freeze
  DAILY_DISCOVERY_AUDIO_MODES = %w[silent opt_in].freeze

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
    return [ "daily_discoveries must be an array" ] unless
      content.is_a?(Hash) && content["daily_discoveries"].is_a?(Array)

    rows = daily_discoveries
    issues = []
    issues << "daily_discoveries must contain exactly 7 entries" unless rows.size == 7
    rows.each_with_index { |row, index| validate_daily_discovery(row, index, issues) }
    validate_daily_discovery_schedule(rows, issues)
    issues
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
        unknown = expedition_pack_ids.reject { |pack_id| QuizDefinition.catalog.pack_ids.include?(pack_id) }
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

    def validate_daily_discovery(row, index, issues)
      prefix = "daily_discoveries[#{index}]"
      unless row.is_a?(Hash)
        issues << "#{prefix} must be an object"
        return
      end

      issues << "#{prefix}.id is required" if row["id"].to_s.strip.blank?
      issues << "#{prefix}.kind is invalid" unless DAILY_DISCOVERY_KINDS.include?(row["kind"].to_s)
      issues << "#{prefix}.status must be approved" unless DAILY_DISCOVERY_STATUSES.include?(row["status"].to_s)
      issues << "#{prefix}.reference is invalid" unless Scriptures::Reference.known_study?(row["reference"])
      validate_daily_discovery_route(row, prefix, issues)
      issues << "#{prefix}.claim_ids must not be empty" if normalized_claim_ids(row).empty?
      issues << "#{prefix}.artwork_key is required" if row["artwork_key"].to_s.strip.blank?
      issues << "#{prefix}.light_family is required" if row["light_family"].to_s.strip.blank?
      issues << "#{prefix}.depiction_mode is required" if row["depiction_mode"].to_s.strip.blank?
      issues << "#{prefix}.motion is invalid" unless DAILY_DISCOVERY_MOTIONS.include?(row["motion"].to_s)
      issues << "#{prefix}.audio is invalid" unless DAILY_DISCOVERY_AUDIO_MODES.include?(row["audio"].to_s)
      issues << "#{prefix}.scheduled_on is invalid" unless parse_daily_discovery_date(row["scheduled_on"])
      issues << "#{prefix}.timezone is invalid" unless Time.find_zone(row["timezone"].to_s)
      validate_daily_discovery_gate(row, index, "truth_gate", issues)
      validate_daily_discovery_gate(row, index, "experience_gate", issues)
      validate_daily_discovery_locales(row, index, issues)
    end

    def validate_daily_discovery_gate(row, index, key, issues)
      gate = row[key]
      revision = Integer(row["revision"], exception: false)
      reviewed_revision = Integer(gate.is_a?(Hash) ? gate["reviewed_revision"] : nil, exception: false)
      prefix = "daily_discoveries[#{index}].#{key}"
      issues << "#{prefix} must pass the current revision" unless
        revision&.positive? && gate.is_a?(Hash) && gate["status"] == "PASS" && reviewed_revision == revision
    end

    def validate_daily_discovery_route(row, prefix, issues)
      references = Array(row["references"]).map(&:to_s).uniq
      issues << "#{prefix}.references must not be empty" if references.empty?
      issues << "#{prefix}.references contains an invalid study" unless
        references.all? { |study| Scriptures::Reference.known_study?(study) }
      issues << "#{prefix}.references must include reference" unless references.include?(row["reference"].to_s)

      pack_id = row["pack_id"].to_s.presence
      if row["kind"].to_s == "discovery"
        issues << "#{prefix}.pack_id must belong to the expedition" unless
          pack_id && expedition_pack_ids.include?(pack_id)
      elsif pack_id && !expedition_pack_ids.include?(pack_id)
        issues << "#{prefix}.pack_id must belong to the expedition"
      end
    end

    def validate_daily_discovery_locales(row, index, issues)
      %w[copy alt disclosure].each do |key|
        localized = row[key]
        unless localized.is_a?(Hash) && localized.keys.map(&:to_s).sort == Locale::AVAILABLE.sort
          issues << "daily_discoveries[#{index}].#{key} must contain exactly #{Locale::AVAILABLE.join(', ')}"
          next
        end

        localized.each do |locale, value|
          if key == "copy"
            missing = DAILY_DISCOVERY_COPY_FIELDS.reject { |field| value.is_a?(Hash) && value[field].to_s.strip.present? }
            issues << "daily_discoveries[#{index}].copy.#{locale} is missing #{missing.join(', ')}" if missing.any?
          elsif value.to_s.strip.blank?
            issues << "daily_discoveries[#{index}].#{key}.#{locale} is required"
          end
        end
      end
    end

    def validate_daily_discovery_schedule(rows, issues)
      hashes = rows.select { |row| row.is_a?(Hash) }
      ids = hashes.map { |row| row["id"].to_s.strip }.reject(&:blank?)
      dates = hashes.filter_map { |row| parse_daily_discovery_date(row["scheduled_on"]) }
      issues << "daily_discoveries ids must be unique" unless ids.uniq.size == ids.size
      issues << "daily_discoveries scheduled_on dates must be unique" unless dates.uniq.size == dates.size
      issues << "daily_discoveries must use one explicit timezone" unless daily_discovery_time_zone

      unless study_unit&.starts_on && study_unit&.ends_on
        issues << "daily_discoveries require a dated study unit"
        return
      end

      issues << "daily_discoveries must stay inside the study week" unless
        dates.all? { |date| date.between?(study_unit.starts_on, study_unit.ends_on) }
    end

    def normalized_claim_ids(row)
      Array(row["claim_ids"]).filter_map { |claim_id| claim_id.to_s.strip.presence }.uniq
    end

    def parse_daily_discovery_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
end
