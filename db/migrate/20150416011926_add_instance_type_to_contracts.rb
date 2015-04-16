class AddInstanceTypeToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :instance_type, :string
    add_index :contracts, :instance_type
  end
end
