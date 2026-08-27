class AddLocatorPayloadToWards < ActiveRecord::Migration[8.1]
  def change
    add_column :wards, :stake_unit_id, :string
    add_column :wards, :locator_payload, :jsonb
    add_index :wards, :stake_unit_id
  end
end
