class ScriptureCircleModerationReportsController < ApplicationController
  include ReaderCircleNavigation

  def create
    result = ScriptureCircles::Moderations::Report.call(
      person: current_street_person,
      post_id: params[:post_id],
      reason_key: report_params.fetch(:reason_key),
      reason_details: report_params[:reason_details],
      device_digest: street_device_digest
    )
    post = result.report.scripture_circle_post
    notice_key = result.opened ? "scripture_reader.moderation.opened" : "scripture_reader.moderation.reported"
    redirect_to scripture_path(post.scripture_circle_thread.reference, **reader_circle_options(post:)),
      notice: I18n.t(notice_key)
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded,
      ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
    redirect_back fallback_location: scripture_circle_path,
      alert: error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : I18n.t("scripture_reader.errors.invalid")
  end

  private

    def report_params
      params.require(:report).permit(:reason_key, :reason_details)
    end
end
