class AddEditorialContextToScriptureChapterGuides < ActiveRecord::Migration[8.1]
  def change
    add_column :scripture_chapter_guides, :historical_context, :text
    add_column :scripture_chapter_guides, :literary_structure, :text
    add_column :scripture_chapter_guides, :key_terms, :jsonb, null: false, default: []

    add_check_constraint :scripture_chapter_guides,
      "historical_context IS NULL OR char_length(historical_context) <= 1200",
      name: "scripture_guides_historical_context_length"
    add_check_constraint :scripture_chapter_guides,
      "literary_structure IS NULL OR char_length(literary_structure) <= 1200",
      name: "scripture_guides_literary_structure_length"
  end
end
