class CreateVehicleKmRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :vehicle_km_records do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :order_service, foreign_key: true
      t.integer :km, null: false
      t.string :origin, default: 'manual' # manual, vehicle_page, order_service
      t.text :observation
      t.timestamps
    end

    add_index :vehicle_km_records, [:vehicle_id, :created_at]
  end
end
