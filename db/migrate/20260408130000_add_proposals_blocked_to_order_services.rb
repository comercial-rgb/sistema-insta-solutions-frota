class AddProposalsBlockedToOrderServices < ActiveRecord::Migration[5.2]
  def change
    add_column :order_services, :proposals_blocked, :boolean, default: false, null: false
    add_index :order_services, :proposals_blocked
  end
end
