class CreateStockOrderServiceItems < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_order_service_items do |t|
      t.references :order_service, foreign_key: true, null: false
      t.references :stock_item, foreign_key: true, null: false
      t.decimal :quantity, precision: 12, scale: 2, null: false, default: 1.0
      t.decimal :unit_price, precision: 12, scale: 2
      t.integer :labor_type, default: 0, null: false
      t.text :observation
      t.references :added_by, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    add_index :stock_order_service_items, [:order_service_id, :stock_item_id], unique: true, name: 'idx_stock_os_items_unique'
  end
end
