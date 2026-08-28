class AddPosterPathToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :poster_path, :string
  end
end
