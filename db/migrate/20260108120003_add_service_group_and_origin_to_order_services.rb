class AddServiceGroupAndOriginToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_reference :order_services, :service_group, foreign_key: true, index: true
    add_column :order_services, :origin_type, :string
    
    add_index :order_services, :origin_type
  end
end
