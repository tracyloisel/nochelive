class AddListedToWards < ActiveRecord::Migration[8.1]
  def change
    add_column :wards, :listed, :boolean, null: false, default: false
    add_index :wards, :listed, where: "listed = TRUE"

    reversible do |dir|
      dir.up do
        execute "UPDATE wards SET listed = TRUE WHERE code = 'RAMA'"
      end
    end
  end
end
