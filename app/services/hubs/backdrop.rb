module Hubs
  class Backdrop
    CATALOG = Rails.root.join("config/media/hub_backdrops.yml")
    FALLBACK_SRC = "/media/ui/temple-marble-hall.svg"
    MODES = %w[light dark].freeze

    Theme = Struct.new(:mode, :atmosphere, :accent, keyword_init: true)
    Result = Struct.new(:id, :src, :media_key, :theme, :hero, keyword_init: true)

    def self.call(at: Time.current, theme_id: nil, pack_id: nil, mode: nil)
      new(at:, theme_id:, pack_id:, mode:).call
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

    def initialize(at:, theme_id: nil, pack_id: nil, mode: nil)
      @at = at
      @theme_id = theme_id.to_s.presence
      @pack_id = pack_id.to_s.presence
      @mode = MODES.include?(mode.to_s) ? mode.to_s : nil
    end

    def call
      row = match_tagged || weekly || {}
      build(row)
    end

    private

      def match_tagged
        match_signals(tokens_for(@pack_id)) || match_signals(tokens_for(@theme_id))
      end

      def match_signals(signals)
        return if signals.empty?

        matching = themed_entries.select { |row| (tags_for(row) & signals).any? }
        matching.first
      end

      def weekly
        list = themed_entries
        return if list.empty?
        return list.find { |row| row["default_for_mode"] } || list.first if @mode

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
          hero: row["hero"].to_s.presence
        )
      end

      def themed_entries
        return self.class.entries unless @mode

        matching = self.class.entries.select { |row| theme_mode_for(row) == @mode }
        matching.presence || self.class.entries
      end

      def theme_mode_for(row)
        raw = row.dig("theme", "mode").to_s
        MODES.include?(raw) ? raw : "light"
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
