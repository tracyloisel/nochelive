class AddSoloToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :solo, :boolean, default: false, null: false
  end
end
