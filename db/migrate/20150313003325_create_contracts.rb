class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.string :name
      t.string :instance_id
      t.string :smash_client

      t.timestamps null: false
    end
  end
end
