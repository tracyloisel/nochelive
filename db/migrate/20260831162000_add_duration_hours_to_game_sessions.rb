class AddDurationHoursToGameSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :duration_hours, :integer, default: 1, null: false
    add_check_constraint :game_sessions,
                         "duration_hours BETWEEN 1 AND 8",
                         name: "game_sessions_duration_hours_range"
  end
end
