class AddQuantityToPartServiceOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :part_service_order_services, :quantity, :decimal, precision: 10, scale: 2, default: 1.0
  end
end
