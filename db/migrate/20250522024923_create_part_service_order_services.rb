class CreatePartServiceOrderServices < ActiveRecord::Migration[7.1]
  def change
    create_table :part_service_order_services do |t|
      t.references :order_service, index: true, foreign_key: true
      t.references :service, index: true, foreign_key: true

      t.timestamps
    end
  end
end
