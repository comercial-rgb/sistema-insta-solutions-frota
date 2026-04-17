class AddIsGerenteToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_gerente, :boolean, default: false, null: false
  end
end
