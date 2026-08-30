class ScriptureCirclesController < ApplicationController
  def show
    access = ScriptureCircles::Access.new(person: current_street_person).readable!
    @reference = params[:reference].to_s
    @thread = access.thread_for(reference: @reference)
    @posts = @thread ? @thread.scripture_circle_posts
      .includes(:person, :parent, scripture_circle_moderation_proposals: [ :proposer_person, :scripture_circle_moderation_ballots ])
      .order(created_at: :desc, id: :desc).limit(20).to_a.reverse : []
    @circle_mode = access.ward.scripture_circle_mode
    @ward = access.ward
  rescue ScriptureCircles::Access::Error
    head :forbidden
  end
end
