module Hubs
  class Backdrop
    CATALOG = Rails.root.join("config/media/hub_backdrops.yml")
    FALLBACK_SRC = "/media/ui/temple-marble-hall.svg"
    MODES = %w[light dark].freeze

    Theme = Struct.new(:mode, :atmosphere, :accent, keyword_init: true)
    Result = Struct.new(:id, :src, :media_key, :theme, :tags, keyword_init: true)

    def self.call(at: Time.current, theme_id: nil, pack_id: nil, randomize: false, exclude_id: nil, random: Random)
      new(at:, theme_id:, pack_id:, randomize:, exclude_id:, random:).call
    end

    def self.tagged(theme_id:, at: Time.current)
      return if theme_id.blank?

      new(at:, theme_id:).tagged
    end

    def self.reset!
      @entries = nil
    end

    def self.entries
      @entries ||= Array(YAML.safe_load_file(CATALOG)["backdrops"])
    end

    def self.entries=(rows)
      @entries = rows
    end

    def initialize(at:, theme_id: nil, pack_id: nil, randomize: false, exclude_id: nil, random: Random)
      @at = at
      @theme_id = theme_id.to_s.presence
      @pack_id = pack_id.to_s.presence
      @randomize = randomize
      @exclude_id = exclude_id.to_s.presence
      @random = random
    end

    def call
      row = randomized || match_tagged || weekly || {}
      build(row)
    end

    def tagged
      row = match_tagged
      build(row) if row
    end

    private

      def match_tagged
        signals = tokens_for(@theme_id) + tokens_for(@pack_id)
        return if signals.empty?

        self.class.entries.find { |row| (tags_for(row) & signals).any? }
      end

      def randomized
        return unless @randomize

        list = self.class.entries
        alternatives = list.reject { |row| row["id"].to_s == @exclude_id }
        alternatives = list if alternatives.empty?
        alternatives.sample(random: @random)
      end

      def weekly
        list = self.class.entries
        return if list.empty?

        list[(@at.to_date.cweek - 1) % list.size]
      end

      def build(row)
        src = media_src(row["image"]) || FALLBACK_SRC
        theme_row = row["theme"].is_a?(Hash) ? row["theme"] : {}
        mode = MODES.include?(theme_row["mode"].to_s) ? theme_row["mode"].to_s : "light"
        Result.new(
          id: row["id"].to_s.presence || "hall",
          src:,
          media_key: row["id"].present? ? "hub.backdrop.#{row.fetch('id')}" : nil,
          theme: Theme.new(
            mode:,
            atmosphere: theme_row["atmosphere"].to_s.presence || "peaceful",
            accent: theme_row["accent"].to_s.presence || "gold"
          ),
          tags: tags_for(row)
        )
      end

      def tags_for(row)
        Array(row["tags"]).map { |tag| tag.to_s.downcase }
      end

      def tokens_for(signal)
        return [] if signal.blank?

        slug = signal.to_s.downcase
        [ slug ] + slug.split(/[_\s-]+/).reject(&:blank?)
      end

      def media_src(rel)
        return if rel.blank?

        rel = rel.to_s.delete_prefix("/")
        rel = "media/#{rel}" unless rel.start_with?("media/")
        asset = Frontend::MediaManifest.fetch_source(rel)
        return asset.fetch("variants").fetch("webp").last.fetch("src") if asset

        "/#{rel}" if Rails.public_path.join(rel).file?
      end
  end
end
