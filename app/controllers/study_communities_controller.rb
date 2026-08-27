class StudyCommunitiesController < ApplicationController
  READERS_PAGE_SIZE = 100

  def show
    @ward = Wards::Enter.call(code: params[:ward_code])
    remember_ward(@ward)
    @week = StudyProgram.order(year: :desc).first&.current_week
    total = Studies::Community.call(ward: @ward, week: @week, completed: true, limit: 0).players
    @readers_pages = [ (total.to_f / READERS_PAGE_SIZE).ceil, 1 ].max
    @readers_page = params.fetch(:readers_page, 1).to_i.clamp(1, @readers_pages)
    @community = Studies::Community.call(
      ward: @ward, week: @week, completed: true,
      offset: (@readers_page - 1) * READERS_PAGE_SIZE, limit: READERS_PAGE_SIZE
    )
    @rows = @community.rows
    @readers_total = total
  end
end
