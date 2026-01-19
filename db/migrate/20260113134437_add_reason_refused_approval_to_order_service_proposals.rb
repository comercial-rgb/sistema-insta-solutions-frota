class AddReasonRefusedApprovalToOrderServiceProposals < ActiveRecord::Migration[7.1]
  def change
    add_column :order_service_proposals, :reason_refused_approval, :text
    add_column :order_service_proposals, :refused_by_manager_id, :bigint
    add_column :order_service_proposals, :refused_by_manager_at, :datetime
  end
end
