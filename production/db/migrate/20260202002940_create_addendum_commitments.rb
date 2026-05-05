class CreateAddendumCommitments < ActiveRecord::Migration[7.1]
  def change
    create_table :addendum_commitments do |t|
      t.references :commitment, null: false, foreign_key: true
      t.string :number
      t.text :description
      t.decimal :total_value, precision: 15, scale: 2
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
