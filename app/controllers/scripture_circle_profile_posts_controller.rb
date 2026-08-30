class ScriptureCircleProfilePostsController < ApplicationController
  def index
    @profile_person = Person.find(params[:player_id])
    @result = ScriptureCircles::ProfilePosts.call(
      viewer_person: current_street_person,
      profile_person: @profile_person,
      cursor: params[:cursor]
    )
  rescue ScriptureCircles::Access::Error
    head :forbidden
  end
end
