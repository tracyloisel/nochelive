class WardAddsController < ApplicationController
  def show
    @ward = Wards::Search.call(query: "").first
  end
end
