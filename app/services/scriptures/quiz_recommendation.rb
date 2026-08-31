module Scriptures
  class QuizRecommendation
    Recommendation = Struct.new(
      :pack_id, :title, :kicker, :question_count, :state,
      keyword_init: true
    )

    def self.call(reference:, world:, locale: I18n.locale, catalog: QuizDefinition.catalog)
      new(reference:, world:, locale:, catalog:).call
    end

    def initialize(reference:, world:, locale:, catalog:)
      @reference = reference.to_s
      @world = world
      @locale = locale
      @catalog = catalog
    end

    def call
      pack = @catalog.packs.find { |candidate| matching_questions(candidate).any? }
      return unless pack

      pack_view = Array(@world&.packs).find { |candidate| candidate.id == pack.id }
      return unless pack_view

      I18n.with_locale(@locale) do
        Recommendation.new(
          pack_id: pack.id,
          title: pack.copy(:title),
          kicker: pack.copy(:kicker),
          question_count: matching_questions(pack).size,
          state: pack_view.state.to_sym
        )
      end
    rescue QuizDefinition::Error
      nil
    end

    private

      def matching_questions(pack)
        pack.questions.select { |question| question.scripture&.study.to_s == @reference }
      end
  end
end
