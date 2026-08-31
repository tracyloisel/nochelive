module Scriptures
  class QuizRecommendation
    Recommendation = Struct.new(
      :pack_id, :title, :kicker, :question_count, :state, :expedition_id,
      keyword_init: true
    )

    def self.call(reference:, world:, locale: I18n.locale, catalog: QuizDefinition.catalog, expedition: nil)
      new(reference:, world:, locale:, catalog:, expedition:).call
    end

    def initialize(reference:, world:, locale:, catalog:, expedition:)
      @reference = reference.to_s
      @world = world
      @locale = locale
      @catalog = catalog
      @expedition = expedition
    end

    def call
      pack = candidate_packs.find { |candidate| matching_questions(candidate).any? }
      return unless pack

      pack_view = Array(@world&.packs).find { |candidate| candidate.id == pack.id }
      return unless pack_view

      expedition_pack = Array(@expedition&.packs).find { |candidate| candidate.id == pack.id }

      I18n.with_locale(@locale) do
        Recommendation.new(
          pack_id: pack.id,
          title: expedition_pack&.title || pack.copy(:title),
          kicker: expedition_pack&.kicker || pack.copy(:kicker),
          question_count: matching_questions(pack).size,
          state: expedition_pack&.state || pack_view.state.to_sym,
          expedition_id: expedition_pack ? @expedition.study_unit_id : nil
        )
      end
    rescue QuizDefinition::Error
      nil
    end

    private

      def candidate_packs
        expedition_packs = Array(@expedition&.pack_ids).filter_map { |id| @catalog.find_pack(id) }
        expedition_packs + (@catalog.packs - expedition_packs)
      end

      def matching_questions(pack)
        pack.questions.select { |question| question.scripture&.study.to_s == @reference }
      end
  end
end
