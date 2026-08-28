class StudyUnit < ApplicationRecord
  KINDS = %w[introduction reflection week appendix].freeze

  belongs_to :study_program
  has_many :study_quiz_versions, dependent: :destroy
  has_many :reading_progresses, dependent: :destroy

  validates :slug, :kind, :position, :title, :source_url, :status, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :slug, uniqueness: { scope: :study_program_id }

  scope :weeks, -> { where(kind: "week").order(:starts_on) }
  scope :appendices, -> { where(kind: "appendix").order(:position) }
  scope :resources, -> { where(kind: %w[introduction reflection appendix]).order(:position) }

  def week?
    kind == "week"
  end

  def appendix?
    kind == "appendix"
  end

  def published_quiz
    if study_quiz_versions.loaded?
      study_quiz_versions.select { |version| version.status == "published" }.max_by(&:version)
    else
      study_quiz_versions.where(status: "published").order(version: :desc).first
    end
  end

  def display_title(locale = I18n.locale)
    locale = Locale.i18n(locale)
    copy.dig(locale.to_s, "title").presence || fallback_display_title(locale)
  end

  def display_period(locale = I18n.locale)
    display_title(locale).split(/\s*:\s*/, 2).first if week?
  end

  def display_heading(locale = I18n.locale)
    display_title(locale).split(/\s*:\s*/, 2).last
  end

  def display_scripture_refs(locale = I18n.locale)
    locale = Locale.i18n(locale)
    localized = copy.dig(locale.to_s, "scripture_refs")
    return localized if localized.present?
    return [ display_heading(locale) ] if week?

    scripture_refs
  end

  def theme(locale = I18n.locale)
    copy.dig(locale.to_s, "theme").presence || copy.dig("fr", "theme").presence || title
  end

  private

    def fallback_display_title(locale)
      return title unless week? && starts_on && ends_on

      "#{localized_period(locale)}: #{localized_heading(locale)}"
    end

    def localized_period(locale)
      start_month = I18n.t("study.program_calendar.months", locale:).fetch(starts_on.month)
      end_month = I18n.t("study.program_calendar.months", locale:).fetch(ends_on.month)
      start_day = localized_day(starts_on.day, locale)
      end_day = localized_day(ends_on.day, locale)
      range = starts_on.month == ends_on.month ? "same_month" : "different_months"

      I18n.t(
        "study.program_calendar.#{range}", locale:,
        start: start_day, finish: end_day, start_month:, end_month:, month: start_month
      )
    end

    def localized_day(day, locale)
      return day unless day == 1

      I18n.t("study.program_calendar.first_day", locale:, default: day)
    end

    def localized_heading(locale)
      source_locale = Locale.i18n(study_program.locale)
      heading = title.split(/\s*:\s*/, 2).last.dup
      replacements = scripture_book_replacements(source_locale, locale) + program_term_replacements(source_locale, locale)
      replacements.sort_by { |source, _target| -source.length }.each do |source, target|
        heading.gsub!(source, target)
      end
      heading.gsub!(/\s*;\s*/, locale == :fr ? " ; " : "; ")
      heading
    end

    def scripture_book_replacements(source_locale, locale)
      Scriptures::Reference::BOOKS.values.filter_map do |book|
        source = book.dig(:names, source_locale)&.last
        target = book.dig(:names, locale)&.last
        [ source, target ] if source.present? && target.present? && source != target
      end
    end

    def program_term_replacements(source_locale, locale)
      %i[introduction_old_testament moses abraham easter christmas].filter_map do |term|
        source = I18n.t("study.program_terms.#{term}", locale: source_locale, default: nil)
        target = I18n.t("study.program_terms.#{term}", locale:, default: nil)
        [ source, target ] if source.present? && target.present? && source != target
      end
    end
end
