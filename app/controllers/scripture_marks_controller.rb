class ScriptureMarksController < ApplicationController
  def create
    return head :unauthorized unless current_street_person

    attributes = mark_params.to_h.symbolize_keys
    attributes[:locale] = Locale.cast(attributes[:locale] || I18n.locale)
    attributes[:bookmarked_at] = Time.current if ActiveModel::Type::Boolean.new.cast(attributes.delete(:bookmark))
    mark = Scriptures::Marks::Create.call(
      person: current_street_person,
      attributes:,
      tag_names: params.dig(:mark, :tag_names),
      notebook_title: params.dig(:mark, :notebook_title),
      target_reference: params.dig(:mark, :target_reference)
    )
    render json: mark.reader_attributes, status: :created
  rescue ActionController::ParameterMissing, ActiveRecord::RecordInvalid => error
    render json: { errors: mark_errors(error) }, status: :unprocessable_entity
  end

  def update
    return head :unauthorized unless current_street_person

    payload = params.require(:mark)
    attributes = mark_params.to_h.symbolize_keys
    attributes[:bookmarked_at] = Time.current if ActiveModel::Type::Boolean.new.cast(attributes.delete(:bookmark))
    mark = Scriptures::Marks::Update.call(
      person: current_street_person,
      mark_id: params[:id],
      attributes:,
      tag_names: payload[:tag_names],
      notebook_title: payload[:notebook_title],
      target_reference: payload[:target_reference],
      replace_tags: payload.key?(:tag_names),
      replace_notebook: payload.key?(:notebook_title),
      replace_link: payload.key?(:target_reference)
    )
    render json: mark.reader_attributes
  rescue ActionController::ParameterMissing, ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    return head :unauthorized unless current_street_person

    mark = current_street_person.scripture_marks.find(params[:id])
    mark.update!(discarded_at: Time.current)
    head :no_content
  end

  def restore
    return head :unauthorized unless current_street_person

    mark = current_street_person.scripture_marks.find(params[:id])
    mark.update!(discarded_at: nil)
    render json: mark.reader_attributes
  end

  private

    def mark_params
      params.require(:mark).permit(
        :reference, :locale, :anchor_scope, :start_verse, :start_offset, :end_verse, :end_offset,
        :selected_text, :source_digest, :visual_style, :color_key, :bookmark, :bookmarked_at,
        :intent_key, :note_body, :tag_names, :notebook_title, :target_reference
      )
    end

    def mark_errors(error)
      error.respond_to?(:record) ? error.record.errors.full_messages : [ I18n.t("scripture_reader.errors.invalid") ]
    end
end
