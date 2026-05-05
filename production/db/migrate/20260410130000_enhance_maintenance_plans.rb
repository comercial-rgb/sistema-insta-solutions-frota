class EnhanceMaintenancePlans < ActiveRecord::Migration[6.1]
  def change
    add_reference :maintenance_plans, :client, foreign_key: { to_table: :users }, null: true
    add_column :maintenance_plans, :description, :text
    add_column :maintenance_plans, :active, :boolean, default: true

    create_table :maintenance_plan_vehicles do |t|
      t.references :maintenance_plan, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.timestamps
    end

    add_index :maintenance_plan_vehicles, [:maintenance_plan_id, :vehicle_id], unique: true, name: 'idx_mp_vehicles_unique'
    add_index :maintenance_plans, :active
  end
end
