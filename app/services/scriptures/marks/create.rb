module Scriptures
  module Marks
    class Create
      MARK_ATTRIBUTES = %i[
        reference locale anchor_scope start_verse start_offset end_verse end_offset selected_text
        source_digest visual_style color_key bookmarked_at intent_key note_body
      ].freeze

      def self.call(person:, attributes:, tag_names: [], notebook_title: nil, target_reference: nil)
        new(person:, attributes:, tag_names:, notebook_title:, target_reference:).call
      end

      def initialize(person:, attributes:, tag_names:, notebook_title:, target_reference:)
        @person = person
        @attributes = attributes.to_h.symbolize_keys.slice(*MARK_ATTRIBUTES)
        @tag_names = Array(tag_names).flat_map { |value| value.to_s.split(",") }.map(&:squish).compact_blank.first(8)
        @notebook_title = notebook_title.to_s.squish.presence
        @target_reference = target_reference.to_s.squish.presence
      end

      def call
        ScriptureMark.transaction do
          mark = @person.scripture_marks.new(@attributes)
          mark.pending_related_annotation = @tag_names.any? || @notebook_title.present? || @target_reference.present?
          mark.save!
          assign_tags(mark)
          assign_notebook(mark)
          assign_link(mark)
          mark.reload
        end
      end

      private

        def assign_tags(mark)
          @tag_names.each do |name|
            normalized = ScriptureTag.normalize(name)
            next if normalized.blank?
            tag = @person.scripture_tags.create_or_find_by!(normalized_name: normalized) { |row| row.name = name }
            mark.scripture_mark_taggings.create_or_find_by!(scripture_tag: tag)
          end
        end

        def assign_notebook(mark)
          return unless @notebook_title
          notebook = @person.scripture_notebooks.find_or_create_by!(title: @notebook_title)
          notebook.scripture_notebook_entries.create_or_find_by!(scripture_mark: mark)
        end

        def assign_link(mark)
          return unless @target_reference

          mark.scripture_mark_links.create!(
            target_reference: @target_reference,
            target_locale: mark.locale
          )
        end
    end
  end
end
