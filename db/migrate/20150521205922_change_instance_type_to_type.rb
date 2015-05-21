class ChangeInstanceTypeToType < ActiveRecord::Migration
  def change
    rename_column :contacts, :instance_type, :type # Rails will automatically populate a type field from the name of a subclass. Ex: 'Spot', 'OnDemand' See Single Table Inheritance for more info
  end
end
