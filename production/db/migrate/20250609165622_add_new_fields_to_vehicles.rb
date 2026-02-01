class AddNewFieldsToVehicles < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicles, :model_year, :string
    add_column :vehicles, :current_owner_name, :string
    add_column :vehicles, :old_owner_name, :string
    add_column :vehicles, :current_owner_document, :string
  end
end
