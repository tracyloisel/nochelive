module Quizzes
  class Chrome
    CATALOG = Rails.root.join("config/media/quiz_stills.yml")
    MODES = %w[light dark].freeze
    ATMOSPHERES = %w[peaceful dramatic solemn glorious].freeze
    GLASSES = %w[soft medium strong].freeze

    Result = Struct.new(:mode, :atmosphere, :glass, :image, keyword_init: true)

    def self.call(question:)
      new(question:).call
    end

    def self.mode_for(image)
      return if image.blank?

      rel = image.to_s.delete_prefix("/").sub(/\Amedia\//, "")
      raw = (stills[rel] || stills["media/#{rel}"] || {})["mode"].to_s
      MODES.include?(raw) ? raw : nil
    end

    def self.ceremony(outcomes: [])
      result_states = Array(outcomes).compact.map(&:to_sym)
      if result_states.include?(:ahead)
        Result.new(
          mode: "light", atmosphere: "glorious", glass: "soft",
          image: "media/social/campus-duel-victory-friends-v1.png"
        )
      elsif result_states.include?(:behind)
        Result.new(
          mode: "dark", atmosphere: "dramatic", glass: "strong",
          image: "media/social/campus-duel-rematch-storm-v1.png"
        )
      else
        Result.new(
          mode: "light", atmosphere: "glorious", glass: "soft",
          image: "media/social/campus-ceremony-friends-v1.png"
        )
      end
    end

    def self.reset!
      @stills = nil
    end

    def self.stills
      @stills ||= Hash(YAML.safe_load_file(CATALOG)["stills"])
    end

    def self.stills=(rows)
      @stills = rows
    end

    def initialize(question:)
      @question = question
    end

    def call
      image = @question.presentation&.[]("image").to_s
      row = self.class.stills[image] || {}
      Result.new(
        mode: pick(row["mode"], MODES, "light"),
        atmosphere: pick(row["atmosphere"], ATMOSPHERES, "peaceful"),
        glass: pick(row["glass"], GLASSES, "medium"),
        image:
      )
    end

    private

      def pick(value, allowed, fallback)
        raw = value.to_s
        allowed.include?(raw) ? raw : fallback
      end
  end
end
