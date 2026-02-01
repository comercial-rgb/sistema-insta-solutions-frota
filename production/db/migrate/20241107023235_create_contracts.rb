class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts do |t|
      t.references :client, index: true, foreign_key: { to_table: :users }
      t.string :name
      t.string :initial_date
      t.string :number
      t.decimal :total_value, :precision => 15, :scale => 2
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
