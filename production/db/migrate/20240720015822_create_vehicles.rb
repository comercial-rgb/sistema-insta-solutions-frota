class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.references :client, index: true, foreign_key: { to_table: :users }
      t.references :cost_center, foreign_key: true, index: true
      t.references :sub_unit, foreign_key: true, index: true
      t.string :board
      t.string :brand
      t.string :model
      t.string :year
      t.string :color
      t.string :renavam
      t.string :chassi
      t.decimal :market_value, :precision => 15, :scale => 2
      t.date :acquisition_date
      t.references :vehicle_type, foreign_key: true, index: true
      t.references :category, foreign_key: true, index: true
      t.references :state, foreign_key: true, index: true
      t.references :city, foreign_key: true, index: true
      t.references :fuel_type, foreign_key: true, index: true
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
