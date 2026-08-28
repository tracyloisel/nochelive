class AddSelectedTextToScriptureHighlights < ActiveRecord::Migration[8.1]
  def change
    add_column :scripture_highlights, :selected_text, :text
  end
end
