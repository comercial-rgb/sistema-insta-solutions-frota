class AddWarrantyStartDateToOrderServiceProposalItems < ActiveRecord::Migration[7.0]
  def change
    add_column :order_service_proposal_items, :warranty_start_date, :date, after: :warranty_period
    add_index :order_service_proposal_items, :warranty_start_date
  end
end
