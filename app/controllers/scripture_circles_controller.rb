class ScriptureCirclesController < ApplicationController
  # Legacy chapter-scoped Circle links still open the reader at that chapter.
  def show
    return redirect_legacy_reference if legacy_reference_request?

    @screen = ScriptureCircles::RamaScreen.call(
      person: current_street_person,
      locale: I18n.locale,
      view: params[:view],
      conversation: params[:conversation],
      page: params[:page]
    )

    # Turbo extracts the matching frame from this layout-free response. The
    # same `show` markup therefore remains the accessible non-JavaScript page.
    render :show, layout: false if turbo_frame_request?
  rescue ScriptureCircles::Access::Error
    # Do not disclose whether another ward has Circle data. This matches the
    # existing access contract for guests, people without a ward, and disabled
    # wards.
    head :forbidden
  end

  private

    def legacy_reference_request?
      params[:reference].present?
    end

    def redirect_legacy_reference
      reference = params[:reference].to_s
      return head :not_found unless Scriptures::Reference.known_study?(reference)

      redirect_to scripture_path(reference, locale: I18n.locale, circle: 1)
    end
end
