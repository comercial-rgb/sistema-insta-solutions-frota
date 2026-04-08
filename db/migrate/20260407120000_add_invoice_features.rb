class AddInvoiceFeatures < ActiveRecord::Migration[5.1]
  def change
    # Esfera do cliente (municipal, estadual, federal)
    add_column :users, :government_sphere, :integer, default: 2, null: false
    # 0 = municipal, 1 = estadual, 2 = federal

    # Marcar OS como faturada
    add_column :order_services, :invoiced, :boolean, default: false, null: false
    add_column :order_services, :invoiced_at, :datetime, null: true

    add_index :order_services, :invoiced
  end
end
