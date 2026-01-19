class CreateProviderServiceTemps < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_service_temps do |t|
      t.references :order_service_proposal, foreign_key: true, index: true
      t.string :name
      t.string :code
      t.decimal :price, :precision => 15, :scale => 2
      t.references :category, foreign_key: true, index: true
      t.text :description
      t.integer :quantity
      t.decimal :discount, :precision => 15, :scale => 2
      t.decimal :total_value, :precision => 15, :scale => 2
      t.string :brand
      t.integer :warranty_period

      t.timestamps
    end
  end
end
