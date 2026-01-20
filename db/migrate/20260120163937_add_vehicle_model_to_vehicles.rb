class AddVehicleModelToVehicles < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicles, :vehicle_model_id, :bigint
    add_column :vehicles, :model_text_normalized, :string
    
    add_index :vehicles, :vehicle_model_id
    add_index :vehicles, :model_text_normalized
    
    add_foreign_key :vehicles, :vehicle_models
  end
end
