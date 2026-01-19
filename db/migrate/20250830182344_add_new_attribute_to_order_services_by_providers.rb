class AddNewAttributeToOrderServicesByProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :parts_services_added, :boolean, default: false
  end
end
