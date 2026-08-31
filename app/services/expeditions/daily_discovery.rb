module Expeditions
  # Resolves the Council-approved cover for one exact local calendar date.
  # Missing, stale or partially approved editorial data intentionally returns
  # nil: callers own the non-editorial Library fallback.
  class DailyDiscovery
    Result = Data.define(
      :id, :kind, :scheduled_on, :time_zone, :locale, :reference, :claim_ids,
      :eyebrow, :title, :setup, :question, :cta_label, :artwork_key,
      :light_family, :depiction_mode, :certainty, :disclosure, :alt, :motion,
      :audio
    ) do
      def contemplation? = kind == "contemplation"
    end

    def self.call(quiz:, locale:, at: Time.current, time_zone:)
      new(quiz:, locale:, at:, time_zone:).call
    end

    def initialize(quiz:, locale:, at:, time_zone:)
      @quiz = quiz
      @locale = locale.to_s
      @at = at
      @time_zone = time_zone.to_s
    end

    def call
      return unless published_source?
      return unless Locale::AVAILABLE.include?(@locale)

      zone = Time.find_zone(@time_zone)
      return unless zone

      local_date = @at.in_time_zone(zone).to_date
      return unless inside_study_week?(local_date)
      return unless @quiz.daily_discoveries_publishable?

      rows = @quiz.daily_discoveries.select do |row|
        row["timezone"].to_s == @time_zone && parse_date(row["scheduled_on"]) == local_date
      end
      return unless rows.one?

      build(rows.first, local_date)
    rescue ArgumentError, NoMethodError, TypeError
      nil
    end

    private

      def published_source?
        return false unless @quiz.is_a?(StudyQuizVersion) && @quiz.persisted?
        return false unless @quiz.status == "published" && @quiz.published_at && @quiz.published_at <= @at
        return false unless @quiz.content_digest_current?

        unit = @quiz.study_unit
        unit.status == "published" && unit.study_program.status == "published"
      end

      def inside_study_week?(date)
        unit = @quiz.study_unit
        unit.starts_on && unit.ends_on && date.between?(unit.starts_on, unit.ends_on)
      end

      def build(row, local_date)
        copy = row.dig("copy", @locale)
        Result.new(
          id: row.fetch("id"),
          kind: row.fetch("kind"),
          scheduled_on: local_date,
          time_zone: @time_zone,
          locale: @locale,
          reference: row.fetch("reference"),
          claim_ids: Array(row["claim_ids"]).map(&:to_s).uniq.freeze,
          eyebrow: copy.fetch("eyebrow"),
          title: copy.fetch("title"),
          setup: copy.fetch("setup"),
          question: copy.fetch("question"),
          cta_label: copy.fetch("cta_label"),
          artwork_key: row.fetch("artwork_key"),
          light_family: row.fetch("light_family"),
          depiction_mode: row.fetch("depiction_mode"),
          certainty: row["certainty"],
          disclosure: row.dig("disclosure", @locale),
          alt: row.dig("alt", @locale),
          motion: row.fetch("motion"),
          audio: row.fetch("audio")
        )
      end

      def parse_date(value)
        Date.iso8601(value.to_s)
      rescue Date::Error
        nil
      end
  end
end
