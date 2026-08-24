class AddPendingRankUpToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :pending_rank_up, :string
  end
end
