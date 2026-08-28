module Seo
  class ChurchPage
    LOCALES = Seo::DiscoveryPage::LOCALES
    SECTIONS = {
      es: "iglesia-de-jesucristo", fr: "eglise-de-jesus-christ",
      en: "church-of-jesus-christ", "pt-BR": "igreja-de-jesus-cristo"
    }.freeze
    PAGES = {
      church: { es: "", fr: "", en: "", "pt-BR": "" },
      church_meet: { es: "hablar-con-misioneros", fr: "parler-aux-missionnaires", en: "meet-missionaries", "pt-BR": "falar-com-missionarios" },
      church_beliefs: { es: "creencias", fr: "croyances", en: "beliefs", "pt-BR": "crencas" },
      church_missionaries: { es: "misioneros", fr: "missionnaires", en: "missionaries", "pt-BR": "missionarios" },
      church_worship: { es: "culto-del-domingo", fr: "culte-du-dimanche", en: "sunday-worship", "pt-BR": "reuniao-dominical" }
    }.freeze

    Result = Data.define(:key, :locale, :route_locale, :section, :slug)

    def self.resolve(locale:, section:, slug: "")
      route_locale = locale.to_s.downcase
      i18n_locale = LOCALES[route_locale]
      return unless i18n_locale && section.to_s == SECTIONS.fetch(i18n_locale)

      normalized = slug.to_s.delete_prefix("/").delete_suffix("/")
      key = PAGES.find { |_key, slugs| slugs.fetch(i18n_locale) == normalized }&.first
      Result.new(key:, locale: i18n_locale, route_locale:, section:, slug: normalized) if key
    end

    def self.path_options(key, locale)
      locale = locale.to_sym
      { locale: LOCALES.key(locale), church_section: SECTIONS.fetch(locale), church_page: PAGES.fetch(key).fetch(locale) }
    end

    def self.all = PAGES.keys
  end
end
