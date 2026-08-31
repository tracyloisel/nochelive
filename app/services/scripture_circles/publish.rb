module ScriptureCircles
  class Publish
    ATTRIBUTES = %i[kind locale body parent_id start_verse end_verse selected_text selected_verses anonymous author_visibility].freeze

    def self.call(person:, reference:, attributes:, device_digest: nil)
      access = Access.new(person:)
      access.writable!
      RateLimit.check!(action: :post, person:, device_digest:)
      thread = access.thread_for(reference:, create: true)
      values = attributes.to_h.symbolize_keys.slice(*ATTRIBUTES)
      parent = access.post!(values.delete(:parent_id), write: true) if values[:parent_id].present?
      values[:kind] = "reply" if parent
      visibility = requested_visibility(values:, parent:)
      values[:author_visibility] = visibility
      values[:anonymous] = visibility == "anonymous_to_ward"
      values[:conversation_root_id] = parent.conversation_root_id || parent.root_post.id if parent

      post = ScriptureCirclePost.transaction do
        thread.scripture_circle_posts.create!(values.merge(ward: access.ward, person:, parent:))
      end
      RamaRefresh.call(ward: access.ward)
      post
    end

    def self.requested_visibility(values:, parent:)
      explicit = values[:author_visibility].to_s.presence
      return explicit if explicit

      legacy_anonymous = ActiveModel::Type::Boolean.new.cast(values[:anonymous])
      return "anonymous_to_ward" if legacy_anonymous && parent.blank? && values[:kind] == "question"

      "named"
    end
    private_class_method :requested_visibility
  end
end
