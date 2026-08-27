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

    def self.ceremony
      Result.new(mode: "light", atmosphere: "glorious", glass: "soft", image: "ceremony-gateway")
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
