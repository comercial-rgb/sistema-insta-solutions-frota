class AddParentStockItemIdToStockItems < ActiveRecord::Migration[7.0]
  def change
    add_column :stock_items, :parent_stock_item_id, :bigint
    add_index :stock_items, :parent_stock_item_id
    add_foreign_key :stock_items, :stock_items, column: :parent_stock_item_id
  end
end
