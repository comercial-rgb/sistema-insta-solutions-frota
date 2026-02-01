class AddSubUnitReferenceToCommitments < ActiveRecord::Migration[7.1]
  def change
    add_reference :commitments, :sub_unit, index: true, foreign_key: true
  end
end
