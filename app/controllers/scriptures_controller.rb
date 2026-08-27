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
    remember_study_reading if @chapter
    render :frame, layout: false if turbo_frame_request?
  end

  private

    def remember_study_reading
      person = current_street_person
      unit = StudyUnit.find_by(id: params[:study_unit_id])
      quiz = unit&.published_quiz
      return unless person && quiz
      return unless quiz.readings.any? { |reading| reading["study"] == @study }

      ReadingProgress.find_or_create_by!(person:, study_unit: unit, reference: @study) do |progress|
        progress.status = "opened"
      end
    end
end
