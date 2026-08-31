class ScriptureCirclePostVotesController < ApplicationController
  include ReaderCircleNavigation

  def update
    result = ScriptureCircles::PostVotes::Cast.call(
      person: current_street_person,
      post_id: params[:post_id],
      direction: post_vote_params.fetch(:direction),
      device_digest: street_device_digest
    )
    post = result.post

    redirect_to scripture_path(
      post.scripture_circle_thread.reference,
      **reader_circle_options(post: post.root_post, focus: false),
      anchor: "circle-post-#{post.id}"
    )
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded, ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: scripture_circle_path, alert: post_vote_error(error)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

    def post_vote_params
      params.require(:post_vote).permit(:direction)
    end

    def post_vote_error(error)
      return I18n.t("scripture_reader.circle.rate_limited") if error.is_a?(ScriptureCircles::RateLimit::Exceeded)
      return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

      I18n.t("scripture_reader.errors.invalid")
    end
end
