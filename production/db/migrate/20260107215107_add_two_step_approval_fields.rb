class AddTwoStepApprovalFields < ActiveRecord::Migration[7.1]
  def change
    add_column :order_service_proposals, :approved_by_additional_id, :bigint
    add_column :order_service_proposals, :authorized_by_additional_id, :bigint
    add_column :order_service_proposals, :approved_by_additional_at, :datetime
    add_column :order_service_proposals, :authorized_by_additional_at, :datetime
    add_column :order_service_proposals, :pending_manager_approval, :boolean, default: false
    add_column :order_service_proposals, :pending_manager_authorization, :boolean, default: false
    
    add_foreign_key :order_service_proposals, :users, column: :approved_by_additional_id
    add_foreign_key :order_service_proposals, :users, column: :authorized_by_additional_id
    add_index :order_service_proposals, :approved_by_additional_id
    add_index :order_service_proposals, :authorized_by_additional_id
    add_index :order_service_proposals, :pending_manager_approval
    add_index :order_service_proposals, :pending_manager_authorization
  end
end
