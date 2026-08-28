class SeoController < ApplicationController
  def sitemap
    @entries = Seo::DiscoveryPage.all.flat_map do |key|
      localized_entries do |locale|
        discovery_url(
          **Seo::DiscoveryPage.path_options(key, locale),
          **sitemap_url_options
        )
      end
    end
    Seo::ChurchPage.all.each do |key|
      @entries.concat(localized_entries do |locale|
        localized_church_url(**Seo::ChurchPage.path_options(key, locale), **sitemap_url_options)
      end)
    end
    Scriptures::Reference.books.each do |book|
      @entries.concat(localized_entries do |locale|
        scripture_book_url(
          **Scriptures::Reference.book_path_options(book, locale),
          **sitemap_url_options
        )
      end)
    end
    Scriptures::Reference.chapters.each do |chapter|
      @entries.concat(localized_entries do |locale|
        scripture_chapter_url(
          **Scriptures::Reference.chapter_path_options(chapter, locale),
          **sitemap_url_options
        )
      end)
    end
    Scriptures::Reference.indexable_passages.each do |passage|
      entries = localized_entries do |locale|
        scripture_passage_url(
          **Scriptures::Reference.passage_path_options(passage.reference, locale, to: passage.to),
          **sitemap_url_options
        )
      end
      @entries.concat(entries)
    end
    Ward.listed.find_each do |ward|
      entries = localized_entries do |locale|
        localized_ward_profile_url(
          **Seo::WardPage.path_options(ward, locale),
          **sitemap_url_options
        )
      end
      @entries.concat(entries)
    end
    @entries.uniq! { |entry| entry[:location] }
    expires_in 1.hour, public: true
  end

  private

    def localized_entries
      alternates = I18n.available_locales.to_h { |locale| [ locale.to_s.downcase, yield(locale) ] }
      alternates["x-default"] = alternates.fetch("es")
      I18n.available_locales.map do |locale|
        { location: alternates.fetch(locale.to_s.downcase), alternates: }
      end
    end

    def sitemap_url_options
      if Rails.env.production?
        { host: Rails.configuration.x.app_host, protocol: "https" }
      else
        { host: request.host_with_port, protocol: request.protocol }
      end
    end
end
