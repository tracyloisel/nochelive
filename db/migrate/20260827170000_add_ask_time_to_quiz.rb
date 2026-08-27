class AddAskTimeToQuiz < ActiveRecord::Migration[8.1]
  def change
    add_column :quiz_runs, :asked_at, :datetime
    add_column :quiz_answers, :duration_ms, :integer
  end
end
