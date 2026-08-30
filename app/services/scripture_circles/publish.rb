module ScriptureCircles
  class Publish
    ATTRIBUTES = %i[kind locale body parent_id start_verse end_verse selected_text anonymous].freeze

    def self.call(person:, reference:, attributes:, device_digest: nil)
      access = Access.new(person:)
      access.writable!
      RateLimit.check!(action: :post, person:, device_digest:)
      thread = access.thread_for(reference:, create: true)
      values = attributes.to_h.symbolize_keys.slice(*ATTRIBUTES)
      parent = access.post!(values.delete(:parent_id), write: true) if values[:parent_id].present?
      values[:kind] = "reply" if parent
      thread.scripture_circle_posts.create!(values.merge(ward: access.ward, person:, parent:))
    end
  end
end
