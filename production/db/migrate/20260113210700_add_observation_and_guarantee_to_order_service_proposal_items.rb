class AddObservationAndGuaranteeToOrderServiceProposalItems < ActiveRecord::Migration[7.1]
  def change
    add_column :order_service_proposal_items, :observation, :text
    add_column :order_service_proposal_items, :guarantee, :string
  end
end
