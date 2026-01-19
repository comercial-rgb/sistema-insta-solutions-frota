class AddNewAttributeToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :data_inserted_by_provider, :boolean, default: false
  end
end
