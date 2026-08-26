class ScripturesController < ApplicationController
  def show
    @study = params[:study].to_s
    unless Quizzes::Scripture.known_study?(@study)
      head :not_found
      return
    end

    @cite = params[:cite].to_s
    @source_url = Quizzes::Scripture.page_url(@study)
    @chapter = Scriptures::Read.call(study: @study, locale: I18n.locale, cite: @cite)
    render :frame, layout: false if turbo_frame_request?
  end
end
