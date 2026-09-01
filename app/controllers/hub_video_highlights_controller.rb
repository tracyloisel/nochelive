class HubVideoHighlightsController < ApplicationController
  def show
    @videos = Hubs::VideoHighlights.call(locale: I18n.locale)
    render layout: false
  end
end
