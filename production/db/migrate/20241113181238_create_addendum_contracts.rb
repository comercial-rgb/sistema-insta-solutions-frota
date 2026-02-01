class CreateAddendumContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :addendum_contracts do |t|
      t.references :contract, foreign_key: true, index: true
      t.string :name
      t.string :number
      t.decimal :total_value, :precision => 15, :scale => 2
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
