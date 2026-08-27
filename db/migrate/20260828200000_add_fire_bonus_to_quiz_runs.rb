class AddFireBonusToQuizRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :quiz_runs, :base_score, :integer, default: 0, null: false
    add_column :quiz_runs, :fire_count, :integer, default: 0, null: false
    add_column :quiz_runs, :fire_bonus, :integer, default: 0, null: false
  end
end
