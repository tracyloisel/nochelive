class ScriptureCircleConversationVotesController < ApplicationController
  include ReaderCircleNavigation

  def update
    result = ScriptureCircles::ConversationVotes::Cast.call(
      person: current_street_person,
      conversation_root_id: params[:conversation_root_id],
      direction: conversation_vote_params.fetch(:direction),
      device_digest: street_device_digest
    )
    root = result.conversation_root

    redirect_to scripture_path(
      root.scripture_circle_thread.reference,
      **reader_circle_options(post: root, focus: false),
      anchor: "circle-post-#{root.id}"
    )
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded, ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: study_program_path, alert: conversation_vote_error(error)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

    def conversation_vote_params
      params.require(:conversation_vote).permit(:direction)
    end

    def conversation_vote_error(error)
      return I18n.t("scripture_reader.circle.rate_limited") if error.is_a?(ScriptureCircles::RateLimit::Exceeded)
      return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

      I18n.t("scripture_reader.errors.invalid")
    end
end
