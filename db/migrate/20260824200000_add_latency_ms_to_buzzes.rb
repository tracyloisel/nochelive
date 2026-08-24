class AddLatencyMsToBuzzes < ActiveRecord::Migration[8.0]
  def change
    add_column :buzzes, :latency_ms, :integer, null: false, default: 0
  end
end
