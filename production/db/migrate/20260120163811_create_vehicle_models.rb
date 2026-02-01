class CreateVehicleModels < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_models do |t|
      t.bigint :vehicle_type_id
      t.string :brand, null: false
      t.string :model, null: false
      t.string :version
      t.string :full_name
      t.text :aliases
      t.string :code_cilia
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :vehicle_models, :vehicle_type_id
    add_index :vehicle_models, :brand
    add_index :vehicle_models, :model
    add_index :vehicle_models, :code_cilia, unique: true
    add_index :vehicle_models, :active
    
    add_foreign_key :vehicle_models, :vehicle_types
  end
end
