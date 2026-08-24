class AddLocationToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :location, :string, null: false, default: "room"
  end
end
