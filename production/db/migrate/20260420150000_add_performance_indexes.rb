class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    unless index_exists?(:order_service_proposals, [:order_service_id, :order_service_proposal_status_id], name: 'idx_osp_os_status')
      add_index :order_service_proposals,
                [:order_service_id, :order_service_proposal_status_id],
                name: 'idx_osp_os_status',
                algorithm: :inplace
    end

    unless index_exists?(:order_service_proposals, [:order_service_proposal_status_id, :updated_at], name: 'idx_osp_status_updated')
      add_index :order_service_proposals,
                [:order_service_proposal_status_id, :updated_at],
                name: 'idx_osp_status_updated',
                algorithm: :inplace
    end

    unless index_exists?(:order_services, [:client_id, :order_service_status_id], name: 'idx_os_client_status')
      add_index :order_services,
                [:client_id, :order_service_status_id],
                name: 'idx_os_client_status',
                algorithm: :inplace
    end

    unless index_exists?(:order_services, [:vehicle_id, :order_service_status_id], name: 'idx_os_vehicle_status')
      add_index :order_services,
                [:vehicle_id, :order_service_status_id],
                name: 'idx_os_vehicle_status',
                algorithm: :inplace
    end

    unless index_exists?(:notifications, [:display_type, :created_at], name: 'idx_notifications_display_created')
      add_index :notifications,
                [:display_type, :created_at],
                name: 'idx_notifications_display_created',
                algorithm: :inplace
    end
  end
end
