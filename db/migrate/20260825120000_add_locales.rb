class AddLocales < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :locale, :string, null: false, default: "es"
    add_column :players, :locale, :string, null: false, default: "es"
    add_column :game_sessions, :presenter_locale, :string, null: false, default: "es"
  end
end
