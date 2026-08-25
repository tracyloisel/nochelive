class AddPersonToQuizRuns < ActiveRecord::Migration[8.1]
  def change
    add_reference :quiz_runs, :person, foreign_key: true
    add_index :quiz_runs, [ :device_digest, :person_id, :status ], name: "index_quiz_runs_on_device_person_status"
  end
end
