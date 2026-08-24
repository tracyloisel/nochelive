class CreateMissionariesAndFourDigitYears < ActiveRecord::Migration[8.1]
  def up
    create_table :missionaries do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    execute <<~SQL.squish
      UPDATE people SET favorite_year = 1833 WHERE favorite_year < 1000
    SQL
    change_column :people, :favorite_year, :integer, null: false
    add_check_constraint :people, "favorite_year >= 1000", name: "people_favorite_year_four_digits"
  end

  def down
    remove_check_constraint :people, name: "people_favorite_year_four_digits"
    drop_table :missionaries
  end
end
