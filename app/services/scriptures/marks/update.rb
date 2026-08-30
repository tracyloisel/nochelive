module Scriptures
  module Marks
    class Update
      ATTRIBUTES = %i[visual_style color_key bookmarked_at intent_key note_body].freeze

      def self.call(person:, mark_id:, attributes:, tag_names: nil, notebook_title: nil, target_reference: nil,
        replace_tags: false, replace_notebook: false, replace_link: false)
        mark = person.scripture_marks.find(mark_id)
        ScriptureMark.transaction do
          replace_tags(mark, person, tag_names) if replace_tags
          replace_notebook(mark, person, notebook_title) if replace_notebook
          replace_link(mark, target_reference) if replace_link
          mark.update!(attributes.to_h.symbolize_keys.slice(*ATTRIBUTES))
          mark.reload
        end
      end

      def self.replace_tags(mark, person, values)
        names = Array(values).flat_map { |value| value.to_s.split(",") }.map(&:squish).compact_blank.first(8)
        tags = names.filter_map do |name|
          normalized = ScriptureTag.normalize(name)
          next if normalized.blank?
          person.scripture_tags.create_or_find_by!(normalized_name: normalized) { |row| row.name = name }
        end
        mark.scripture_mark_taggings.where.not(scripture_tag_id: tags.map(&:id)).delete_all
        tags.each { |tag| mark.scripture_mark_taggings.create_or_find_by!(scripture_tag: tag) }
      end
      private_class_method :replace_tags

      def self.replace_notebook(mark, person, title)
        mark.scripture_notebook_entries.delete_all
        normalized = title.to_s.squish.presence
        return unless normalized
        notebook = person.scripture_notebooks.find_or_create_by!(title: normalized)
        mark.scripture_notebook_entries.create!(scripture_notebook: notebook)
      end
      private_class_method :replace_notebook

      def self.replace_link(mark, reference)
        mark.scripture_mark_links.delete_all
        normalized = reference.to_s.squish.presence
        return unless normalized
        mark.scripture_mark_links.create!(target_reference: normalized, target_locale: mark.locale)
      end
      private_class_method :replace_link
    end
  end
end
