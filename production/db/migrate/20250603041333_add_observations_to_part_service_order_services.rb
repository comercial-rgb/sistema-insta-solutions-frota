class AddObservationsToPartServiceOrderServices < ActiveRecord::Migration[7.1]
  def change
    add_column :part_service_order_services, :observation, :text
  end
end
