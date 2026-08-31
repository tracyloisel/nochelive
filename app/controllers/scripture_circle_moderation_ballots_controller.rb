class ScriptureCircleModerationBallotsController < ApplicationController
  include ReaderCircleNavigation

  def update
    ballot = ScriptureCircles::Moderations::CastBallot.call(
      person: current_street_person,
      proposal_id: params[:proposal_id],
      choice: ballot_params.fetch(:choice),
      device_digest: street_device_digest
    )
    post = ballot.scripture_circle_moderation_proposal.scripture_circle_post
    redirect_to scripture_path(post.scripture_circle_thread.reference, **reader_circle_options(post:)),
      notice: I18n.t("scripture_reader.moderation.vote_saved")
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded, ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: scripture_circle_path,
      alert: error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : I18n.t("scripture_reader.errors.invalid")
  end

  private

    def ballot_params
      params.require(:ballot).permit(:choice)
    end
end
