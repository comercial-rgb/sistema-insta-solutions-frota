class AddContractToAddendumCommitments < ActiveRecord::Migration[7.1]
  def change
    add_reference :addendum_commitments, :contract, null: true, foreign_key: true
  end
end
