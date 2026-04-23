class AddOrderServiceToMaintenanceAlerts < ActiveRecord::Migration[7.0]
  def change
    add_column :maintenance_alerts, :order_service_id, :bigint
    add_index :maintenance_alerts, :order_service_id
    add_foreign_key :maintenance_alerts, :order_services, column: :order_service_id
  end
end
