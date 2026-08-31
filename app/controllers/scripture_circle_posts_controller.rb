class ScriptureCirclePostsController < ApplicationController
  include ReaderCircleNavigation

  def create
    attributes = post_params
    post = ScriptureCircles::Publish.call(
      person: current_street_person,
      reference: attributes.fetch(:reference),
      attributes: attributes.except(:reference),
      device_digest: street_device_digest
    )
    event = post.kind == "reply" ? "replied" : "published"
    return render_circle_frame(post:) if circle_frame_request?

    redirect_to scripture_path(post.scripture_circle_thread.reference, **reader_circle_options(post:, event:)),
      notice: I18n.t("scripture_reader.circle.#{event}")
  rescue KeyError, ScriptureCircles::Access::Error, ScriptureCircles::RateLimit::Exceeded, ActiveRecord::RecordInvalid => error
    return render_circle_failure(error) if circle_frame_request?

    redirect_back fallback_location: study_program_path,
      alert: circle_error(error)
  end

  def update
    attributes = post_params
    post = ScriptureCircles::Posts::Update.call(
      person: current_street_person,
      post_id: params[:id],
      body: attributes.fetch(:body),
      author_visibility: attributes[:author_visibility]
    )
    return render_circle_frame(post:) if circle_frame_request?

    redirect_to scripture_path(post.scripture_circle_thread.reference, **reader_circle_options(post:, event: "updated")),
      notice: I18n.t("scripture_reader.circle.updated")
  rescue KeyError, ScriptureCircles::Access::Error, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => error
    return render_circle_failure(error) if circle_frame_request?

    redirect_back fallback_location: study_program_path, alert: circle_error(error)
  end

  def destroy
    post = ScriptureCircles::Posts::Destroy.call(person: current_street_person, post_id: params[:id])
    return render_circle_frame(post:) if circle_frame_request?

    redirect_back fallback_location: scripture_path(post.scripture_circle_thread.reference, **reader_circle_options(post:, focus: false)),
      notice: I18n.t("scripture_reader.circle.deleted")
  rescue ScriptureCircles::Access::Error, ActiveRecord::RecordInvalid => error
    return render_circle_failure(error) if circle_frame_request?

    redirect_back fallback_location: study_program_path, alert: circle_error(error)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

    def post_params
      params.require(:post).permit(
        :reference, :kind, :locale, :body, :parent_id, :start_verse, :end_verse, :selected_text, :selected_verses, :author_visibility
      )
    end

    def circle_error(error)
      return I18n.t("scripture_reader.circle.rate_limited") if error.is_a?(ScriptureCircles::RateLimit::Exceeded)
      return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

      I18n.t("scripture_reader.errors.invalid")
    end

    def circle_frame_request?
      turbo_frame_request? && request.headers["Turbo-Frame"] == "circle_live_feed"
    end

    def render_circle_failure(error)
      @circle_draft = post_params.to_h
      @circle_error = circle_error(error)
      render_circle_frame(status: :unprocessable_entity)
    end

    def render_circle_frame(post: nil, status: :ok)
      @screen = ScriptureCircles::RamaScreen.call(
        person: current_street_person,
        locale: I18n.locale,
        view: circle_view_for(post),
        conversation: circle_conversation_id(post),
        page: params[:circle_page]
      )
      render template: "scripture_circles/show", layout: false, status: status
    end

    def circle_conversation_id(post)
      params[:circle_conversation].presence || post&.conversation_root_id || post&.id
    end

    def circle_view_for(post)
      requested_view = params[:circle_view].to_s
      return "mine" if post&.kind == "reply" && requested_view == "help"

      requested_view
    end
  end
