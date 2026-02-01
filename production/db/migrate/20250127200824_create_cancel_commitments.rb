class CreateCancelCommitments < ActiveRecord::Migration[7.1]
  def change
    create_table :cancel_commitments do |t|
      t.references :commitment, foreign_key: true, index: true
      t.decimal :value, :precision => 15, :scale => 2
      t.string :number
      t.date :date

      t.timestamps
    end
  end
end
