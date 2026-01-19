class CreateRejectedOrderServicesToProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :rejected_order_services_providers, id: false do |t|
      t.references :order_service, foreign_key: true, index: true
      t.references :provider, index: true, foreign_key: { to_table: :users }
    end
  end
end
