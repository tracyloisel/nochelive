class MigrateScriptureHighlightsToMarks < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO scripture_marks (
        person_id, reference, locale, anchor_scope,
        start_verse, start_offset, end_verse, end_offset,
        selected_text, visual_style, color_key, created_at, updated_at
      )
      SELECT
        highlights.person_id, highlights.reference, highlights.locale, 'passage',
        highlights.start_verse, highlights.start_offset, highlights.end_verse, highlights.end_offset,
        highlights.selected_text, 'highlight', 'gold', highlights.created_at, highlights.updated_at
      FROM scripture_highlights highlights
      WHERE NOT EXISTS (
        SELECT 1 FROM scripture_marks marks
        WHERE marks.person_id = highlights.person_id
          AND marks.reference = highlights.reference
          AND marks.locale = highlights.locale
          AND marks.anchor_scope = 'passage'
          AND marks.start_verse = highlights.start_verse
          AND marks.start_offset = highlights.start_offset
          AND marks.end_verse = highlights.end_verse
          AND marks.end_offset = highlights.end_offset
      )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "legacy highlights remain intact; migrated marks may have been edited"
  end
end
