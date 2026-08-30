class ScriptureReadingProgressesController < ApplicationController
  def update
    return head :unauthorized unless current_street_person

    progress = Scriptures::ReadingProgress::Record.call(
      person: current_street_person,
      reference: progress_params.fetch(:reference),
      locale: progress_params[:locale] || I18n.locale,
      last_verse: progress_params.fetch(:last_verse),
      last_offset: progress_params[:last_offset],
      progress_ratio: progress_params.fetch(:progress_ratio),
      completed: progress_params[:completed]
    )
    render json: {
      last_verse: progress.last_verse,
      progress_ratio: progress.progress_ratio.to_f,
      completed_at: progress.completed_at&.iso8601
    }
  rescue ActionController::ParameterMissing, KeyError, ActiveRecord::RecordInvalid => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  private

    def progress_params
      params.require(:progress).permit(
        :reference, :locale, :last_verse, :last_offset, :progress_ratio, :completed
      )
    end
end
