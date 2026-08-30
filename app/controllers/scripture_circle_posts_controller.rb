class ScriptureCirclePostsController < ApplicationController
  def create
    post = ScriptureCircles::Publish.call(
      person: current_street_person,
      reference: post_params.fetch(:reference),
      attributes: post_params.except(:reference),
      device_digest: street_device_digest
    )
    event = post.kind == "reply" ? "replied" : "published"
    redirect_to scripture_path(post.scripture_circle_thread.reference, locale: post.locale, circle: 1, circle_post: post.id, circle_event: event),
      notice: I18n.t("scripture_reader.circle.#{event}")
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded, ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: study_program_path,
      alert: circle_error(error)
  end

  def update
    attributes = post_params
    post = ScriptureCircles::Posts::Update.call(
      person: current_street_person,
      post_id: params[:id],
      body: attributes.fetch(:body),
      anonymous: attributes.key?(:anonymous) ? attributes[:anonymous] : nil
    )
    redirect_to scripture_path(post.scripture_circle_thread.reference, locale: post.locale, circle: 1, circle_post: post.id, circle_event: "updated"),
      notice: I18n.t("scripture_reader.circle.updated")
  rescue KeyError, ScriptureCircles::Access::Error, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => error
    redirect_back fallback_location: study_program_path, alert: circle_error(error)
  end

  def destroy
    post = ScriptureCircles::Posts::Destroy.call(person: current_street_person, post_id: params[:id])
    redirect_back fallback_location: scripture_path(post.scripture_circle_thread.reference, locale: post.locale, circle: 1),
      notice: I18n.t("scripture_reader.circle.deleted")
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

    def post_params
      params.require(:post).permit(
        :reference, :kind, :locale, :body, :parent_id, :start_verse, :end_verse, :selected_text, :anonymous
      )
    end

    def circle_error(error)
      return I18n.t("scripture_reader.circle.rate_limited") if error.is_a?(ScriptureCircles::RateLimit::Exceeded)
      return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

      I18n.t("scripture_reader.errors.invalid")
    end
end
