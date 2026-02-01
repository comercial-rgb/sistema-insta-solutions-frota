class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.references :provider, index: true, foreign_key: { to_table: :users }
      t.string :name
      t.string :code
      t.decimal :price, :precision => 15, :scale => 2
      t.references :category, foreign_key: true, index: true
      t.text :description
      t.string :brand
      t.integer :warranty_period

      t.timestamps
    end
  end
end
