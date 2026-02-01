class CreateOrderServiceProposalItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_proposal_items do |t|
      t.references :order_service_proposal, foreign_key: true, index: true
      t.references :service, foreign_key: true, index: true
      t.integer :quantity
      t.decimal :discount, :precision => 15, :scale => 2
      t.decimal :total_value, :precision => 15, :scale => 2
      t.decimal :unity_value, :precision => 15, :scale => 2
      t.decimal :total_value_without_discount, :precision => 15, :scale => 2
      t.string :service_name
      t.text :service_description
      t.string :brand
      t.integer :warranty_period

      t.timestamps
    end
  end
end
