module Expeditions
  # Council-authored projection used by every Rama page while an expedition is
  # active. Copy and artwork travel together so the page never has to infer a
  # biblical book, translate a fragment, or borrow another surface's visual.
  class RamaHero
    LIGHT_FAMILIES = %w[celestial_light celestial_dark].freeze
    ARTWORK_ROLE = "rama_weekly_hero"
    REQUIRED_RENDITIONS = {
      "portrait" => "9:16",
      "tablet" => "4:5",
      "landscape" => "16:9"
    }.freeze

    Result = Data.define(:headline, :artwork_key, :light_family)

    def self.call(expedition:, locale: I18n.locale)
      new(expedition:).call(locale:)
    end

    def self.validation_errors(expedition:)
      new(expedition:).validation_errors
    end

    def self.artwork_digest_for(artwork_key)
      asset = Frontend::MediaManifest.fetch(artwork_key)
      payload = {
        "artwork_key" => artwork_key.to_s,
        "role" => asset&.dig("role"),
        "theme" => asset&.dig("theme"),
        "renditions" => REQUIRED_RENDITIONS.keys.index_with do |name|
          rendition = asset&.dig("renditions", name) || {}
          rendition.slice(
            "source", "source_sha256", "source_width", "source_height", "ratio"
          )
        end
      }
      StudyQuizVersion.content_digest_for(payload)
    end

    def initialize(expedition:)
      expedition = {} unless expedition.is_a?(Hash)
      @data = expedition["rama_hero"]
    end

    def call(locale:)
      return if validation_errors.any?

      # The Council owns all four public headlines. An unknown locale must not
      # silently turn into Spanish (Locale.cast's general-purpose fallback),
      # otherwise the Rama page would publish copy the Council did not author
      # for that audience.
      locale = locale.to_s
      return unless Locale::AVAILABLE.include?(locale)

      Result.new(
        headline: @data.fetch("headline").fetch(locale),
        artwork_key: @data.fetch("artwork_key").strip,
        light_family: @data.fetch("light_family")
      )
    end

    def validation_errors
      return [ "rama_hero is required" ] unless @data.is_a?(Hash)

      [].tap do |issues|
        unless @data["revision"].is_a?(Integer) && @data["revision"].positive?
          issues << "rama_hero revision must be a positive integer"
        end
        validate_headlines(issues)
        validate_artwork(issues)
        unless LIGHT_FAMILIES.include?(@data["light_family"].to_s)
          issues << "rama_hero light_family must be celestial_light or celestial_dark"
        end
      end
    end

    private

      def validate_headlines(issues)
        headlines = @data["headline"]
        unless headlines.is_a?(Hash)
          issues << "rama_hero headline must contain exactly #{Locale::AVAILABLE.join(', ')}"
          return
        end

        locales = headlines.keys.map(&:to_s)
        unless locales.sort == Locale::AVAILABLE.sort && headlines.values.all? { |value| value.is_a?(String) && value.strip.present? }
          issues << "rama_hero headline must contain exactly #{Locale::AVAILABLE.join(', ')}"
        end
      end

      def validate_artwork(issues)
        artwork_key = @data["artwork_key"].to_s.strip
        if artwork_key.empty?
          issues << "rama_hero artwork_key is required"
          return
        end

        asset = Frontend::MediaManifest.fetch(artwork_key)
        unless asset
          issues << "rama_hero artwork_key must resolve in the media manifest"
          return
        end

        unless asset["role"] == ARTWORK_ROLE
          issues << "rama_hero artwork must use the #{ARTWORK_ROLE} media role"
        end

        renditions = asset["renditions"].is_a?(Hash) ? asset["renditions"] : {}
        unless renditions.keys.sort == REQUIRED_RENDITIONS.keys.sort
          issues << "rama_hero artwork must contain exactly portrait, tablet, landscape renditions"
        end

        sources = REQUIRED_RENDITIONS.filter_map do |name, ratio|
          rendition = renditions[name]
          next unless rendition

          issues << "rama_hero artwork #{name} ratio must be #{ratio}" unless rendition["ratio"] == ratio
          rendition["source"].to_s.presence
        end
        unless sources.size == REQUIRED_RENDITIONS.size && sources.uniq.size == REQUIRED_RENDITIONS.size
          issues << "rama_hero artwork must use three distinct source masters"
        end

        expected_theme = @data["light_family"].to_s.delete_prefix("celestial_")
        if LIGHT_FAMILIES.include?(@data["light_family"].to_s) && asset["theme"] != expected_theme
          issues << "rama_hero light_family must match the artwork theme"
        end

        artwork_digest = @data["artwork_digest"].to_s
        if artwork_digest.blank?
          issues << "rama_hero artwork_digest is required"
        elsif !secure_digest?(artwork_digest, self.class.artwork_digest_for(artwork_key))
          issues << "rama_hero artwork changed after Council review"
        end
      end

      def secure_digest?(left, right)
        left = left.to_s
        right = right.to_s
        left.bytesize == right.bytesize && ActiveSupport::SecurityUtils.secure_compare(left, right)
      end
  end
end
