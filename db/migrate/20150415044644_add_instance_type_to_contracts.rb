class AddInstanceTypeToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :instance_type, :string
  end
end
