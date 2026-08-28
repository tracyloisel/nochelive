module Seo
  class WardPage
    LOCALES = Seo::DiscoveryPage::LOCALES
    SECTIONS = {
      es: "santos-de-los-ultimos-dias",
      fr: "saints-des-derniers-jours",
      en: "latter-day-saints",
      "pt-BR": "santos-dos-ultimos-dias"
    }.freeze

    def self.path_options(ward, locale)
      i18n_locale = Locale.i18n(locale)
      {
        locale: LOCALES.key(i18n_locale),
        ward_section: SECTIONS.fetch(i18n_locale),
        slug: slug(ward)
      }
    end

    def self.resolve(slug)
      Ward.listed.find_each.find { |ward| slug(ward) == slug.to_s.parameterize }
    end

    def self.slug(ward)
      source = ward.city.presence || ward.chapel_name.presence || ward.name
      source.to_s.parameterize
    end

    def self.valid_section?(locale, section)
      SECTIONS.fetch(Locale.i18n(locale)) == section.to_s
    end
  end
end
