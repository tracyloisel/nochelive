module SeoMetadata
  extend ActiveSupport::Concern

  included do
    before_action :initialize_seo_metadata
    after_action :apply_robots_header
    helper_method :seo_metadata
  end

  private

    def initialize_seo_metadata
      @seo_metadata = {
        title: nil,
        robots: private_application_path? ? "noindex, nofollow" : "noindex, follow",
        image: "#{request.base_url}/icon-master.png"
      }
    end

    def apply_robots_header
      robots = @seo_metadata&.fetch(:robots, nil)
      response.set_header("X-Robots-Tag", robots) if robots&.start_with?("noindex")
    end

    def private_application_path?
      request.path.match?(%r{\A/(?:p/|s/|ficha(?:/|\z)|desafio(?:/|\z)|desafios(?:/|\z)|ramas/fichas(?:/|\z)|game_sessions(?:/|\z))})
    end

    def index_for_search!(title:, description:, canonical:, alternates: {}, image: nil, structured_data: nil)
      @seo_metadata = {
        title:,
        description:,
        canonical:,
        alternates:,
        image: image || "#{request.base_url}/icon-master.png",
        robots: "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1",
        structured_data:
      }
    end

    def seo_metadata
      @seo_metadata
    end
end
