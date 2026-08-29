module Frontend
  class ResourceManifest
    CLASSES = %w[critical contextual interaction viewport predictive idle].freeze
    MAX_PREFETCH_BYTES = 180_000

    attr_reader :context, :styles, :controllers, :media, :audio, :motion, :prefetch, :classes

    def self.shell
      new(
        context: "shell",
        styles: %w[shell],
        controllers: %w[loading press],
        classes: {
          "style.shell" => "critical",
          "controller.loading" => "critical",
          "controller.press" => "contextual"
        }
      )
    end

    def initialize(context:, styles: [], controllers: [], media: {}, audio: {}, motion: [], prefetch: {}, classes: {})
      @context = context.to_s
      @styles = normalize_list(styles, :styles)
      @controllers = normalize_list(controllers, :controllers)
      @media = media.to_h.compact.deep_stringify_keys.freeze
      @audio = { "unlock" => false, "cues" => [], "bed" => nil }.merge(audio.to_h.deep_stringify_keys).freeze
      @motion = normalize_list(motion, :motion)
      @prefetch = { "nextScreen" => false, "maxBytes" => 0 }.merge(prefetch.to_h.deep_stringify_keys).freeze
      @classes = classes.to_h.transform_keys(&:to_s).transform_values(&:to_s).freeze
      validate!
      freeze
    end

    def as_json(*)
      {
        context:,
        styles:,
        controllers:,
        media:,
        audio:,
        motion:,
        prefetch:,
        classes:
      }
    end

    def to_json(*)
      as_json.to_json
    end

    private

      def normalize_list(value, name)
        raise ArgumentError, "#{name} must be an array" unless value.is_a?(Array)

        value.map(&:to_s).reject(&:blank?).uniq.freeze
      end

      def validate!
        raise ArgumentError, "invalid frontend context" unless context.match?(/\A[a-z0-9_.-]+\z/i)
        raise ArgumentError, "audio cues must be an array" unless audio["cues"].is_a?(Array)

        bytes = Integer(prefetch["maxBytes"])
        raise ArgumentError, "prefetch budget exceeds #{MAX_PREFETCH_BYTES}" unless bytes.between?(0, MAX_PREFETCH_BYTES)

        unknown = classes.values - CLASSES
        raise ArgumentError, "unknown resource classes: #{unknown.join(', ')}" if unknown.any?
      end
  end
end
