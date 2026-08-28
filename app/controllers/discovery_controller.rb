class DiscoveryController < ApplicationController
  def show
    @page = Seo::DiscoveryPage.resolve(locale: params[:locale], slug: params[:slug])
    return head :not_found unless @page

    @related = Seo::DiscoveryPage.related(@page.key)
    @parent_key = Seo::DiscoveryPage.parent(@page.key)
    canonical = discovery_url(**Seo::DiscoveryPage.path_options(@page.key, @page.locale))
    alternates = I18n.available_locales.to_h do |locale|
      [ locale.to_s.downcase, discovery_url(**Seo::DiscoveryPage.path_options(@page.key, locale)) ]
    end
    alternates["x-default"] = discovery_url(**Seo::DiscoveryPage.path_options(:home, :es))

    response.set_header(
      "Link",
      [
        "<#{Ai::SiteCatalog.markdown_path(@page)}>; rel=\"alternate\"; type=\"text/markdown\"",
        "</llms.txt>; rel=\"describedby\"; type=\"text/plain\""
      ].join(", ")
    )

    index_for_search!(
      title: t("seo.discovery.pages.#{@page.key}.title"),
      description: t("seo.discovery.pages.#{@page.key}.description"),
      canonical:,
      alternates:,
      image: discovery_image,
      structured_data: structured_data(canonical)
    )
    Rails.logger.info("event=seo_landing page=#{@page.key} locale=#{@page.route_locale}")
  end

  private

    def structured_data(canonical)
      page_type = @page.key == :home ? "WebSite" : "CollectionPage"
      graph = [
        {
          "@type": page_type,
          name: t("seo.discovery.pages.#{@page.key}.h1"),
          description: t("seo.discovery.pages.#{@page.key}.description"),
          url: canonical,
          inLanguage: @page.locale.to_s
        },
        {
          "@type": "Organization",
          name: "Noche Live",
          url: discovery_url(**Seo::DiscoveryPage.path_options(:home, @page.locale)),
          logo: "#{request.base_url}/icon-master.png"
        }
      ]
      if @parent_key
        graph << {
          "@type": "BreadcrumbList",
          itemListElement: breadcrumb_items(canonical)
        }
      end
      {
        "@context": "https://schema.org",
        "@graph": graph
      }
    end

    def breadcrumb_items(canonical)
      keys = [ :home, @parent_key, @page.key ].compact.uniq
      keys.each_with_index.map do |key, index|
        url = key == @page.key ? canonical : discovery_url(**Seo::DiscoveryPage.path_options(key, @page.locale))
        { "@type": "ListItem", position: index + 1, name: t("seo.discovery.pages.#{key}.card_title"), item: url }
      end
    end

    def discovery_image
      file = case @page.key
      when :bible_study, :psalms_study then "media/study/psalms-refuge-2026.png"
      when :group_activities, :youth_activities then "media/study/community-scripture-gathering-v1.png"
      else "media/nights/noche_live_stage_v2.png"
      end
      "#{request.base_url}/#{file}"
    end
end
