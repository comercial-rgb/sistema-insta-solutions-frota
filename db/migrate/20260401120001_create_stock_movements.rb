class CreateStockMovements < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_movements do |t|
      t.references :stock_item, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.integer :movement_type, null: false
      t.decimal :quantity, precision: 12, scale: 2, null: false
      t.decimal :unit_price, precision: 12, scale: 2
      t.decimal :balance_after, precision: 12, scale: 2, null: false
      t.text :reason
      t.string :document_number
      t.string :supplier_name
      t.string :supplier_cnpj
      t.string :xml_file_name
      t.references :order_service, foreign_key: true
      t.integer :source, default: 0, null: false

      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :source
    add_index :stock_movements, :document_number
    add_index :stock_movements, :created_at
  end
end
