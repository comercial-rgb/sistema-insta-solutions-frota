class AddCiliaPricingToOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :order_services, :cilia_priced_at, :datetime
    add_column :order_services, :cilia_priced_by_id, :bigint

    add_index :order_services, :cilia_priced_at
    add_index :order_services, :cilia_priced_by_id
  end
end
