class CreateSmashClients < ActiveRecord::Migration
  def change
    create_table :smash_clients do |t|
      t.string :name
      t.string :user

      t.timestamps null: false
    end
  end
end
