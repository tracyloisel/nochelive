class MakeStreetProfilesProgressive < ActiveRecord::Migration[8.0]
  def change
    remove_check_constraint :people, name: "people_favorite_year_four_digits"
    remove_index :people, name: "index_people_on_ficha"
    change_column_null :people, :favorite_year, true
    change_column_null :people, :ward_id, true
    add_index :people, [ :ward_id, :given_name_key, :created_at ], name: "index_people_on_recorded_profile"
  end
end
