class AddCommitmentToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_reference :order_services, :commitment, index: true, foreign_key: true
  end
end
