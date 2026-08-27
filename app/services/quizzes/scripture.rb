module Quizzes
  class Scripture
    LANG = {
      "es" => "spa",
      "en" => "eng",
      "fr" => "fra",
      "pt-BR" => "por"
    }.freeze
    HOST = "https://www.churchofjesuschrist.org/study/scriptures"

    def self.call(question:, locale: I18n.locale)
      url(question, locale:)
    end

    def self.url(question, locale: I18n.locale)
      page_url(question.scripture.study, locale:)
    end

    def self.page_url(study, locale: I18n.locale)
      lang = LANG[locale.to_s] || LANG["es"]
      "#{HOST}/#{study}?lang=#{lang}"
    end

    def self.lang(locale = I18n.locale)
      LANG[locale.to_s] || LANG["es"]
    end

    def self.known_study?(study)
      path = study.to_s
      return false if path.blank?

      QuizDefinition.catalog.all_questions.any? { |question| question.scripture.study == path } ||
        StudyQuizVersion.known_scripture_study?(path)
    end
  end
end
