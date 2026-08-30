class AddAskedAtToStudyRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :study_runs, :asked_at, :datetime
  end
end
