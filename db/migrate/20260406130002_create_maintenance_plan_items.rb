class CreateMaintenancePlanItems < ActiveRecord::Migration[6.1]
  def change
    create_table :maintenance_plan_items do |t|
      t.references :maintenance_plan, null: false, foreign_key: true
      t.references :client, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :plan_type, null: false, default: 'km' # km, days, both
      t.integer :km_interval                            # ex: 10000 (a cada 10.000 km)
      t.integer :days_interval                           # ex: 180 (a cada 180 dias)
      t.integer :km_alert_threshold, default: 1000       # alerta X km antes
      t.integer :days_alert_threshold, default: 15        # alerta X dias antes
      t.text :description
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :maintenance_plan_items, :plan_type
    add_index :maintenance_plan_items, :active
  end
end
