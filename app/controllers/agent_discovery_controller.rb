class AgentDiscoveryController < ApplicationController
  def llms
    render_agent_document(catalog.manifest, content_type: "text/plain")
  end

  def page
    page = Seo::DiscoveryPage.resolve(locale: params[:locale], slug: params[:slug].to_s.delete_suffix(".md"))
    return head :not_found unless page

    document = catalog.page(page)
    response.set_header("Content-Language", page.route_locale)
    response.set_header(
      "Link",
      [
        "<#{catalog.canonical_url(page)}>; rel=\"canonical\"",
        "</llms.txt>; rel=\"describedby\"; type=\"text/plain\""
      ].join(", ")
    )
    render_agent_document(document, content_type: "text/markdown")
  end

  private

    def catalog
      @catalog ||= Ai::SiteCatalog.new(base_url: request.base_url)
    end

    def render_agent_document(document, content_type:)
      expires_in 1.hour, public: true, stale_while_revalidate: 1.day
      fresh_when(etag: document, public: true)
      render plain: document, content_type: "#{content_type}; charset=utf-8" unless performed?
    end
end
