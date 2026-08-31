class ReplacePresenterWithQuizSequence < ActiveRecord::Migration[8.1]
  def up
    add_column :game_sessions, :quiz_pack_ids, :jsonb, null: false, default: []
    execute <<~SQL.squish
      UPDATE game_sessions
      SET quiz_pack_ids = '["coronas"]'::jsonb
      WHERE quiz_pack_ids = '[]'::jsonb
    SQL
    change_column_null :game_sessions, :presenter_token_digest, true
  end

  def down
    execute <<~SQL.squish
      UPDATE game_sessions
      SET presenter_token_digest = repeat('0', 64)
      WHERE presenter_token_digest IS NULL
    SQL
    change_column_null :game_sessions, :presenter_token_digest, false
    remove_column :game_sessions, :quiz_pack_ids
  end
end
