class AddWardChapelAndEmblem < ActiveRecord::Migration[8.1]
  def change
    add_column :wards, :emblem, :string, null: false, default: "paloma"
    add_column :wards, :chapel_name, :string
    add_column :wards, :chapel_address, :string
    add_column :wards, :city, :string
    add_column :wards, :region, :string
    add_column :wards, :postal_code, :string
    add_column :wards, :country_code, :string
    add_column :wards, :latitude, :decimal, precision: 10, scale: 6
    add_column :wards, :longitude, :decimal, precision: 10, scale: 6
    add_index :wards, :city
    add_index :wards, :country_code
  end
end
