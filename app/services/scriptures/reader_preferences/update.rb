module Scriptures
  module ReaderPreferences
    class Update
      ATTRIBUTES = %i[
        font_scale line_height_key measure_key font_family_key background_key illustrations_enabled
      ].freeze

      def self.call(person:, attributes:)
        preference = person.scripture_reader_preference || person.build_scripture_reader_preference
        preference.update!(attributes.to_h.symbolize_keys.slice(*ATTRIBUTES))
        preference
      end
    end
  end
end
