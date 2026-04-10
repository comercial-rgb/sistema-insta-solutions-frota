class CreateDriverVehicleAssignments < ActiveRecord::Migration[7.0]
  def change
    create_table :driver_vehicle_assignments do |t|
      t.references :user, null: false, foreign_key: true, comment: 'Motorista'
      t.references :vehicle, null: false, foreign_key: true
      t.boolean :active, default: true
      t.date :assigned_at
      t.date :unassigned_at

      t.timestamps
    end

    add_index :driver_vehicle_assignments, [:user_id, :vehicle_id, :active], unique: true, name: 'idx_driver_vehicle_active'
  end
end
