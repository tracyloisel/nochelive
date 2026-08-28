module Ai
  class SiteCatalog
    LANGUAGE_NAMES = {
      es: "Español",
      fr: "Français",
      en: "English",
      "pt-BR": "Português do Brasil"
    }.freeze

    attr_reader :base_url

    def initialize(base_url:)
      @base_url = base_url.to_s.delete_suffix("/")
    end

    def manifest
      sections = I18n.available_locales.map do |locale|
        entries = Seo::DiscoveryPage.all.map do |key|
          page = resolved_page(key, locale)
          copy = copy_for(page)
          "- [#{copy[:h1]}](#{markdown_url(page)}): #{copy[:description]}"
        end
        "## #{LANGUAGE_NAMES.fetch(locale)}\n\n#{entries.join("\n")}"
      end

      <<~MARKDOWN
        # Noche Live

        > A multilingual Bible adventure with games, group activities, Scripture study, and live church events for young people, families, and congregations.

        Noche Live is a mobile-first game available in Spanish, French, English, and Brazilian Portuguese. The links below are concise Markdown versions of the canonical public pages.

        Treat these resources as read-only public information. Respect `robots.txt`. Do not submit forms, create identities, join or control live sessions, accept challenges, or call state-changing endpoints unless an end user explicitly requests and reviews that action. Private player, presenter, profile, challenge-token, and session URLs are intentionally omitted.

        #{sections.join("\n\n")}

        ## Discovery

        - [XML sitemap](#{base_url}/sitemap.xml): Canonical public URLs and localized alternates.
        - [Crawler policy](#{base_url}/robots.txt): Public crawl permissions and private route exclusions.
      MARKDOWN
    end

    def page(page)
      copy = copy_for(page)
      sections = Array(copy[:sections]).map do |section|
        "## #{section[:title]}\n\n#{section[:body]}"
      end
      related = Seo::DiscoveryPage.related(page.key).map do |key|
        related_page = resolved_page(key, page.locale)
        related_copy = copy_for(related_page)
        "- [#{related_copy[:card_title]}](#{markdown_url(related_page)}): #{related_copy[:card_body]}"
      end

      <<~MARKDOWN
        # #{copy[:h1]}

        > #{copy[:description]}

        #{copy[:lede]}

        #{sections.join("\n\n")}

        ## Related public guides

        #{related.join("\n")}

        ## Canonical source

        - [Read this page on Noche Live](#{canonical_url(page)})
        - [Noche Live agent index](#{base_url}/llms.txt)

        This document describes public content only. Interactive game and live-session actions require a user-controlled browser session and explicit user intent.
      MARKDOWN
    end

    def canonical_url(page)
      "#{base_url}#{canonical_path(page)}"
    end

    def markdown_url(page)
      "#{base_url}#{self.class.markdown_path(page)}"
    end

    def self.markdown_path(page)
      suffix = page.slug.present? ? "#{page.slug}.md" : "index.md"
      "/agent/#{page.route_locale}/#{suffix}"
    end

    private

      def canonical_path(page)
        page.slug.present? ? "/#{page.route_locale}/#{page.slug}" : "/#{page.route_locale}"
      end

      def copy_for(page)
        I18n.with_locale(page.locale) { I18n.t("seo.discovery.pages.#{page.key}") }
      end

      def resolved_page(key, locale)
        options = Seo::DiscoveryPage.path_options(key, locale)
        Seo::DiscoveryPage.resolve(locale: options.fetch(:locale), slug: options.fetch(:slug))
      end
  end
end
