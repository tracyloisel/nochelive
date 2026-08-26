class WidenWardsForDirectory < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    add_column :wards, :church_unit_id, :string
    add_column :wards, :stake_name, :string
    add_column :wards, :unit_kind, :string
    add_column :wards, :country_name, :string

    add_index :wards, :church_unit_id, unique: true, where: "church_unit_id IS NOT NULL"
    add_index :wards, [ :listed, :country_code, :stake_name ], name: "index_wards_on_listed_country_stake"
    add_index :wards, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_wards_on_name_trgm"
    add_index :wards, :city, using: :gin, opclass: :gin_trgm_ops, name: "index_wards_on_city_trgm"
    add_index :wards, :stake_name, using: :gin, opclass: :gin_trgm_ops, name: "index_wards_on_stake_name_trgm"
  end
end
