class ScriptureHighlightsController < ApplicationController
  def create
    person = current_street_person
    return head :unauthorized unless person

    attributes = highlight_params.to_h.symbolize_keys
    attributes[:locale] = Locale.cast(attributes[:locale] || I18n.locale)
    selected_text = attributes.delete(:selected_text)
    highlight = person.scripture_highlights.find_or_initialize_by(attributes)
    highlight.selected_text = selected_text if selected_text.present?
    highlight.save!
    render json: highlight.reader_attributes, status: :created
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    person = current_street_person
    return head :unauthorized unless person

    person.scripture_highlights.find(params[:id]).destroy!
    head :no_content
  end

  private

    def highlight_params
      params.require(:highlight).permit(
        :reference, :locale, :start_verse, :end_verse, :start_offset, :end_offset, :selected_text
      )
    end
end
