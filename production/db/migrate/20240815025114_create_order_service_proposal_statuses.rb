class CreateOrderServiceProposalStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_proposal_statuses do |t|
      t.string :name

      t.timestamps
    end
  end
end
