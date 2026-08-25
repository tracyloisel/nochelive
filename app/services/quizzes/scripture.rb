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
      lang = LANG[locale.to_s] || LANG["es"]
      "#{HOST}/#{question.scripture.study}?lang=#{lang}"
    end
  end
end
