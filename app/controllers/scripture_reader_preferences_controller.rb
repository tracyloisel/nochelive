class ScriptureReaderPreferencesController < ApplicationController
  def update
    return head :unauthorized unless current_street_person

    preference = Scriptures::ReaderPreferences::Update.call(
      person: current_street_person,
      attributes: preference_params
    )
    render json: preference.reader_attributes
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => error
    render json: { errors: record_errors(error) }, status: :unprocessable_entity
  end

  private

    def preference_params
      params.require(:preference).permit(
        :font_scale, :line_height_key, :measure_key, :font_family_key,
        :background_key, :illustrations_enabled
      )
    end

    def record_errors(error)
      error.respond_to?(:record) ? error.record.errors.full_messages : [ I18n.t("scripture_reader.errors.invalid") ]
    end
end
