class AddReasonSelectedToServiceProposals < ActiveRecord::Migration[7.1]
  def change
    add_column :order_service_proposals, :reason_approved, :text
  end
end
