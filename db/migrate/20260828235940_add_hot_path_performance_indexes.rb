class AddHotPathPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :person_devices, [ :last_seen_at, :person_id ],
      name: "index_person_devices_on_live_presence",
      algorithm: :concurrently
    add_index :quiz_answers, :created_at,
      name: "index_quiz_answers_on_created_at",
      algorithm: :concurrently
    add_index :quiz_answers, [ :pack_id, :question_id, :device_digest, :id ],
      name: "index_quiz_answers_on_tally_lookup",
      algorithm: :concurrently
    add_index :quiz_runs, [ :person_id, :pack_id, :score ],
      name: "index_quiz_runs_on_finished_adventure_scores",
      order: { score: :desc },
      where: "status = 'finished' AND street_duel_id IS NULL",
      algorithm: :concurrently
    add_index :game_sessions, [ :ward_id, :status, :starts_at, :id ],
      name: "index_game_sessions_on_ward_schedule",
      algorithm: :concurrently
    add_index :street_duels, [ :challenger_person_id, :status, :updated_at ],
      name: "index_street_duels_on_challenger_inbox",
      order: { updated_at: :desc },
      algorithm: :concurrently
    add_index :street_duels, [ :opponent_person_id, :status, :updated_at ],
      name: "index_street_duels_on_opponent_inbox",
      order: { updated_at: :desc },
      algorithm: :concurrently
  end
end
