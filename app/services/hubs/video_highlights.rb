module Hubs
  class VideoHighlights
    LIMIT = 6

    class << self
      def call(locale: I18n.locale, catalog: ChurchVideos::Catalog)
        new(locale:, catalog:).call
      end
    end

    def initialize(locale:, catalog:)
      @locale = Locale.cast(locale)
      @catalog = catalog
    end

    def call
      result = @catalog.call(locale: @locale)
      return [] unless result&.available?

      Array(result.videos).first(LIMIT)
    rescue StandardError => error
      Rails.logger.warn("Hubs::VideoHighlights unavailable: #{error.class}")
      []
    end
  end
end
