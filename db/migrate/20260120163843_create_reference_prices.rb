class CreateReferencePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :reference_prices do |t|
      t.bigint :vehicle_model_id, null: false
      t.bigint :service_id, null: false
      t.decimal :reference_price, precision: 15, scale: 2, null: false
      t.decimal :max_percentage, precision: 5, scale: 2, default: 110.0
      t.text :observation
      t.string :source
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :reference_prices, :vehicle_model_id
    add_index :reference_prices, :service_id
    add_index :reference_prices, [:vehicle_model_id, :service_id], unique: true, name: 'index_reference_prices_on_model_and_service'
    add_index :reference_prices, :active
    
    add_foreign_key :reference_prices, :vehicle_models
    add_foreign_key :reference_prices, :services
  end
end
