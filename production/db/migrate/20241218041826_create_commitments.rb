class CreateCommitments < ActiveRecord::Migration[7.1]
  def change
    create_table :commitments do |t|
      t.references :client, index: true, foreign_key: { to_table: :users }
      t.references :cost_center, foreign_key: true, index: true
      t.references :contract, foreign_key: true, index: true
      t.string :commitment_number
      t.decimal :commitment_value, :precision => 15, :scale => 2

      t.timestamps
    end
  end
end
