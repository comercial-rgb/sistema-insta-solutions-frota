class CreateMaintenancePlanItemServices < ActiveRecord::Migration[7.0]
  def change
    create_table :maintenance_plan_item_services do |t|
      t.references :maintenance_plan_item, null: false, foreign_key: true, index: true
      t.references :service, null: false, foreign_key: true, index: true
      t.decimal :quantity, precision: 10, scale: 2, default: 1.0
      t.text :observation

      t.timestamps
    end

    add_index :maintenance_plan_item_services,
              [:maintenance_plan_item_id, :service_id],
              unique: true,
              name: 'idx_plan_item_services_unique'
  end
end
