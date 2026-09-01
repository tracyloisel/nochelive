module Hubs
  # Builds the lower Home rail from chapters the product can actually open.
  # Quiz-informed readings keep precedence, then the published weekly order
  # fills the rail. A chapter appears once even when both sources mention it.
  class ExploreCards
    Card = Data.define(
      :study, :cite, :title, :artwork, :status, :progress_percent,
      :path, :source
    )

    DEFAULT_LIMIT = 8

    def self.call(reading_cards:, weekly_reading_cards:, exclude_studies: [], limit: DEFAULT_LIMIT)
      new(reading_cards:, weekly_reading_cards:, exclude_studies:, limit:).call
    end

    def initialize(reading_cards:, weekly_reading_cards:, exclude_studies:, limit:)
      @reading_cards = Array(reading_cards)
      @weekly_reading_cards = Array(weekly_reading_cards)
      @excluded_studies = Array(exclude_studies).compact_blank.map(&:to_s).to_set
      @limit = limit.to_i.clamp(0, DEFAULT_LIMIT)
      @routes = Rails.application.routes.url_helpers
    end

    def call
      candidates = sourced(@reading_cards, :quiz) + sourced(@weekly_reading_cards, :weekly)
      candidates
        .uniq { |card, _source| card.study }
        .sort_by { |card, source| [ status_rank(card.status), source == :quiz ? 0 : 1 ] }
        .first(@limit)
        .map { |card, source| present(card, source:) }
    end

    private

      def sourced(cards, source)
        cards.filter_map do |card|
          next if card.study.blank? || card.title.blank? || @excluded_studies.include?(card.study.to_s)

          [ card, source ]
        end
      end

      def status_rank(status)
        case status&.to_sym
        when :in_progress then 0
        when :unread then 1
        when :completed then 2
        else 3
        end
      end

      def present(card, source:)
        options = { cite: card.cite }
        if card.respond_to?(:study_unit_id) && card.study_unit_id.present?
          options[:study_unit_id] = card.study_unit_id
        end

        Card.new(
          study: card.study,
          cite: card.cite,
          title: card.title,
          artwork: card.artwork,
          status: card.status,
          progress_percent: card.progress_percent,
          path: @routes.scripture_path(card.study, **options),
          source:
        )
      end
  end
end
