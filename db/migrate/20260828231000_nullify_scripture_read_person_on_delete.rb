class NullifyScriptureReadPersonOnDelete < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :scripture_chapter_reads, :people
    add_foreign_key :scripture_chapter_reads, :people, on_delete: :nullify
  end
end
