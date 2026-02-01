class AddNewAttributeToOrderServicesToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :release_quotation, :boolean, default: false
  end
end
