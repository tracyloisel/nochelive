class AddStreakRewardBreakdownToQuizAnswers < ActiveRecord::Migration[8.1]
  def change
    add_column :quiz_answers, :base_points, :integer
    add_column :quiz_answers, :streak_bonus, :integer
    add_column :quiz_answers, :points_awarded, :integer
    add_column :quiz_answers, :streak_before, :integer
    add_column :quiz_answers, :streak_after, :integer
    add_column :quiz_answers, :bonus_lost, :integer
  end
end
