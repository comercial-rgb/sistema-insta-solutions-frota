class AddActiveToCommitments < ActiveRecord::Migration[6.1]
  def change
    add_column :commitments, :active, :boolean, default: true, null: false
  end
end
