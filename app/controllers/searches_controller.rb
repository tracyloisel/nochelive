class SearchesController < ApplicationController
  def show
    @query = params[:q].to_s
    @wards = Wards::Search.call(query: @query)
  end
end
