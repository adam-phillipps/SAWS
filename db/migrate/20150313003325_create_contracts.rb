class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.belongs_to :smash_client, index: true
      t.string :name
      t.string :instance_id

      t.timestamps null: false
    end
  end
end
