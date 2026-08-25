class NightsController < ApplicationController
  def index
    feed = Nights::Feed.call
    @upcoming = feed[:upcoming]
    @past = feed[:past]
  end
end
