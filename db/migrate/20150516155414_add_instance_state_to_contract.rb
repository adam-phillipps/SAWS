class AddInstanceStateToContract < ActiveRecord::Migration
  def change
    add_column :contracts, :instance_state, :string, default: 'inactive'
  end
end
