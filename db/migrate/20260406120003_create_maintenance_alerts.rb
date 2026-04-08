class CreateMaintenanceAlerts < ActiveRecord::Migration[6.1]
  def change
    create_table :maintenance_alerts do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :maintenance_plan_item, null: false, foreign_key: true
      t.references :client, foreign_key: { to_table: :users }
      t.string :alert_type, null: false # km, days
      t.string :status, default: 'pending' # pending, acknowledged, completed, dismissed
      t.integer :current_km
      t.integer :target_km
      t.date :target_date
      t.text :message
      t.datetime :acknowledged_at
      t.references :acknowledged_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :maintenance_alerts, :status
    add_index :maintenance_alerts, :alert_type
    add_index :maintenance_alerts, [:vehicle_id, :status]
  end
end
