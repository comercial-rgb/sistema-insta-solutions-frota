class CreateServiceGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :service_groups do |t|
      t.string :name, null: false
      t.decimal :value_limit, precision: 10, scale: 2, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :service_groups, :active
  end
end
