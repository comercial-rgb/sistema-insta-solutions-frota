class FixMissingReavaliacaoColumns < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:order_services, :reevaluation_requested_at)
      add_column :order_services, :reevaluation_requested_at, :datetime
    end

    unless column_exists?(:order_services, :reevaluation_requested_by_id)
      add_column :order_services, :reevaluation_requested_by_id, :bigint
      add_index :order_services, :reevaluation_requested_by_id
      add_foreign_key :order_services, :users, column: :reevaluation_requested_by_id, on_delete: :nullify
    end

    unless column_exists?(:provider_service_temps, :is_complement)
      add_column :provider_service_temps, :is_complement, :boolean, default: false
    end
  end

  def down
    remove_foreign_key :order_services, column: :reevaluation_requested_by_id if foreign_key_exists?(:order_services, column: :reevaluation_requested_by_id)
    remove_column :order_services, :reevaluation_requested_by_id if column_exists?(:order_services, :reevaluation_requested_by_id)
    remove_column :order_services, :reevaluation_requested_at if column_exists?(:order_services, :reevaluation_requested_at)
    remove_column :provider_service_temps, :is_complement if column_exists?(:provider_service_temps, :is_complement)
  end
end
