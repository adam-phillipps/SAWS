class AddWorkflowStateToAllTables < ActiveRecord::Migration
  def change
    add_column :users, :workflow_state, :string, null: false, default: 'new'
    add_column :smash_clients, :workflow_state, :string, null: false, default: 'new'
    add_column :contracts, :workflow_state, :string, null: false, default: 'new'
  end
end
