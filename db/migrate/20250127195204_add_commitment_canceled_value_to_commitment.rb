class AddCommitmentCanceledValueToCommitment < ActiveRecord::Migration[7.1]
  def change
    add_column :commitments, :canceled_value, :decimal, :precision => 15, :scale => 2
  end
end
