class CreateServiceGroupItems < ActiveRecord::Migration[7.1]
  def change
    create_table :service_group_items do |t|
      t.references :service_group, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, default: 0
      t.decimal :max_value, precision: 10, scale: 2, default: 0

      t.timestamps
    end
    
    add_index :service_group_items, [:service_group_id, :service_id], unique: true, name: 'index_service_group_items_unique'
  end
end
