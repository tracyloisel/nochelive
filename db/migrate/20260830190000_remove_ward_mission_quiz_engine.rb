class RemoveWardMissionQuizEngine < ActiveRecord::Migration[8.1]
  TABLES = %i[
    ward_mission_answers
    ward_mission_runs
    ward_mission_entries
    ward_mission_stages
    ward_missions
  ].freeze

  def up
    TABLES.each { |table| drop_table(table) if table_exists?(table) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "WardMission was an unshipped duplicate quiz engine"
  end
end
