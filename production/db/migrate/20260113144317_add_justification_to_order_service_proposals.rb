class AddJustificationToOrderServiceProposals < ActiveRecord::Migration[7.1]
  def change
    add_column :order_service_proposals, :justification, :text
  end
end
