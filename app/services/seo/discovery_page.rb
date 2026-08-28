module Seo
  class DiscoveryPage
    LOCALES = {
      "es" => :es,
      "fr" => :fr,
      "en" => :en,
      "pt-br" => :"pt-BR"
    }.freeze

    PAGES = {
      home: { es: "", fr: "", en: "", "pt-BR": "" },
      bible_games: { es: "juegos-biblicos", fr: "jeux-bibliques", en: "bible-games", "pt-BR": "jogos-biblicos" },
      bible_quiz: { es: "juegos-biblicos/trivia-biblica", fr: "jeux-bibliques/quiz-biblique", en: "bible-games/bible-trivia", "pt-BR": "jogos-biblicos/quiz-biblico" },
      group_activities: { es: "actividades-cristianas", fr: "activites-chretiennes", en: "christian-activities", "pt-BR": "atividades-cristas" },
      youth_activities: { es: "actividades-cristianas/jovenes", fr: "activites-chretiennes/jeunes", en: "christian-activities/youth", "pt-BR": "atividades-cristas/jovens" },
      bible_study: { es: "estudio-biblico", fr: "etude-biblique", en: "bible-study", "pt-BR": "estudo-biblico" },
      psalms_study: { es: "estudio-biblico/salmos", fr: "etude-biblique/psaumes", en: "bible-study/psalms", "pt-BR": "estudo-biblico/salmos" }
    }.freeze

    RELATED = {
      home: %i[bible_games group_activities bible_study],
      bible_games: %i[bible_quiz group_activities bible_study],
      bible_quiz: %i[bible_games youth_activities psalms_study],
      group_activities: %i[youth_activities bible_games bible_study],
      youth_activities: %i[group_activities bible_quiz psalms_study],
      bible_study: %i[psalms_study bible_games group_activities],
      psalms_study: %i[bible_study bible_quiz youth_activities]
    }.freeze
    PARENTS = {
      bible_games: :home, bible_quiz: :bible_games,
      group_activities: :home, youth_activities: :group_activities,
      bible_study: :home, psalms_study: :bible_study
    }.freeze

    Result = Data.define(:key, :locale, :route_locale, :slug)

    def self.resolve(locale:, slug: "")
      route_locale = locale.to_s.downcase
      i18n_locale = LOCALES[route_locale]
      return unless i18n_locale

      normalized_slug = slug.to_s.delete_prefix("/").delete_suffix("/")
      key = PAGES.find { |_name, slugs| slugs.fetch(i18n_locale) == normalized_slug }&.first
      Result.new(key:, locale: i18n_locale, route_locale:, slug: normalized_slug) if key
    end

    def self.path_options(key, locale)
      route_locale = LOCALES.key(locale.to_sym)
      { locale: route_locale, slug: PAGES.fetch(key).fetch(locale.to_sym) }
    end

    def self.related(key)
      RELATED.fetch(key)
    end

    def self.all
      PAGES.keys
    end

    def self.parent(key) = PARENTS[key]
  end
end
