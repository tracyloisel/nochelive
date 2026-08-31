class OpenScriptureCirclesByDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_default :wards, :scripture_circle_mode, from: "disabled", to: "active"

    # The original default was introduced with the feature, so existing wards
    # that still carry it have not made an explicit close/read-only choice.
    execute <<~SQL
      UPDATE wards
      SET scripture_circle_mode = 'active'
      WHERE scripture_circle_mode = 'disabled'
    SQL
  end

  def down
    change_column_default :wards, :scripture_circle_mode, from: "active", to: "disabled"
  end
end
