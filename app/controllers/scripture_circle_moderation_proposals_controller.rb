class ScriptureCircleModerationProposalsController < ApplicationController
  def create
    proposal = ScriptureCircles::Moderations::Propose.call(
      person: current_street_person,
      post_id: params[:post_id],
      reason_key: proposal_params.fetch(:reason_key),
      reason_details: proposal_params[:reason_details],
      device_digest: street_device_digest
    )
    redirect_to scripture_path(proposal.scripture_circle_post.scripture_circle_thread.reference, circle: 1),
      notice: I18n.t("scripture_reader.moderation.opened")
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded,
      ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
    redirect_back fallback_location: study_program_path,
      alert: error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : I18n.t("scripture_reader.errors.invalid")
  end

  private

    def proposal_params
      params.require(:proposal).permit(:reason_key, :reason_details)
    end
end
