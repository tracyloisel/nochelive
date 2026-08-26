class PagesController < ApplicationController
  VISIT_URL = "https://www.churchofjesuschrist.org/comeuntochrist"
  BELIEVE_URL = "https://www.churchofjesuschrist.org/comeuntochrist/believe"
  MAPS_URL = "https://www.churchofjesuschrist.org/maps/meetinghouses"

  helper_method :church_visit_url, :church_believe_url, :church_maps_url

  def church; end
  def church_meet; end
  def church_beliefs; end
  def church_missionaries; end
  def church_worship; end
  def legal; end
  def privacy; end
  def stats
    @stats = Platform::Stats.call
  end

  private

    def church_visit_url
      VISIT_URL
    end

    def church_believe_url
      BELIEVE_URL
    end

    def church_maps_url
      MAPS_URL
    end
end
