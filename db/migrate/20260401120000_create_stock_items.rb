class CreateStockItems < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_items do |t|
      t.references :client, foreign_key: { to_table: :users }, null: false
      t.references :cost_center, foreign_key: true, null: false
      t.references :sub_unit, foreign_key: true
      t.string :name, null: false
      t.string :code
      t.string :brand
      t.text :description
      t.decimal :quantity, precision: 12, scale: 2, default: 0.0, null: false
      t.decimal :minimum_quantity, precision: 12, scale: 2, default: 0.0
      t.decimal :unit_price, precision: 12, scale: 2, default: 0.0
      t.string :unit_measure, default: 'UN'
      t.string :ncm
      t.string :part_number
      t.string :location
      t.integer :status, default: 0, null: false
      t.references :category, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :stock_items, [:client_id, :cost_center_id, :code], unique: true, name: 'idx_stock_items_unique_code'
    add_index :stock_items, [:client_id, :cost_center_id, :name], name: 'idx_stock_items_client_cc_name'
    add_index :stock_items, :status
    add_index :stock_items, :part_number
  end
end
