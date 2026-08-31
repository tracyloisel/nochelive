class RemoveLegacyPresenterGame < ActiveRecord::Migration[8.0]
  LEGACY_TABLES = %i[
    audience_reactions audience_responses ballots buzzes cheers pose_holds
    reward_grants score_events tap_runs answers missionaries round_runs
  ].freeze

  def up
    LEGACY_TABLES.each { |table| drop_table(table, if_exists: true) }

    remove_columns :game_sessions,
      :broadcast_delay_ms, :poster_path, :public_token, :season_applied_at,
      :theme_id, :theme_title,
      type: :string
    remove_columns :players, :role, :location, type: :string
    remove_columns :teams,
      :next_correct_doubled, :pending_rank_up, :rank_key, :season_rank_up,
      :solo, :streak, :xp,
      type: :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The presenter game was intentionally deleted without historical compatibility"
  end
end
