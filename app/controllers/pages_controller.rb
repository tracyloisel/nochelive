class PagesController < ApplicationController
  VISIT_URL = "https://www.churchofjesuschrist.org/comeuntochrist"
  BELIEVE_URL = "https://www.churchofjesuschrist.org/comeuntochrist/believe"
  MAPS_URL = "https://www.churchofjesuschrist.org/maps/meetinghouses"
  MISSION_URL = "https://www.churchofjesuschrist.org/callings/missionary"
  PREACH_URL = "https://www.churchofjesuschrist.org/study/manual/preach-my-gospel-2023/03-chapter-1"
  WORSHIP_URL = "https://www.churchofjesuschrist.org/comeuntochrist/belong/sunday-services/what-are-sunday-services-like"

  helper_method :church_visit_url, :church_believe_url, :church_maps_url, :church_mission_url, :church_preach_url, :church_worship_url

  def church; end
  def church_meet; end
  def church_beliefs; end
  def church_missionaries; end
  def church_worship; end
  def localized_church
    @church_page = Seo::ChurchPage.resolve(
      locale: params[:locale], section: params[:church_section], slug: params[:church_page]
    )
    return head :not_found unless @church_page

    title = t("seo.church.pages.#{@church_page.key}.title")
    description = t("seo.church.pages.#{@church_page.key}.description")
    canonical = localized_church_url(**Seo::ChurchPage.path_options(@church_page.key, @church_page.locale))
    alternates = I18n.available_locales.to_h do |locale|
      [ locale.to_s.downcase, localized_church_url(**Seo::ChurchPage.path_options(@church_page.key, locale)) ]
    end
    alternates["x-default"] = localized_church_url(**Seo::ChurchPage.path_options(@church_page.key, :es))
    index_for_search!(title:, description:, canonical:, alternates:, structured_data: {
      "@context": "https://schema.org", "@type": "WebPage", name: title,
      description:, url: canonical, inLanguage: @church_page.locale.to_s
    })
    render @church_page.key
  end
  def legal; end
  def privacy; end
  def stats
    screen = Platform::StatsScreen.call(
      person: current_street_person,
      ward: current_ward,
      device_digest: device_digest
    )
    @screen = screen
    @stats = screen.stats
  end

  private

    def device_digest
      remember_device
      GameSession.digest_token(device_token)
    end

    def church_visit_url
      VISIT_URL
    end

    def church_believe_url
      BELIEVE_URL
    end

    def church_maps_url
      MAPS_URL
    end

    def church_mission_url
      "#{MISSION_URL}?lang=#{mission_language}"
    end

    def church_preach_url
      "#{PREACH_URL}?lang=#{mission_language}"
    end

    def church_worship_url
      "#{WORSHIP_URL}?lang=#{mission_language}"
    end

    def mission_language
      { es: "spa", fr: "fra", en: "eng", :"pt-BR" => "por" }.fetch(I18n.locale.to_sym, "eng")
    end
end
