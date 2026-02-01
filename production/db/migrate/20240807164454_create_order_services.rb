class CreateOrderServices < ActiveRecord::Migration[7.1]
  def change
    create_table :order_services do |t|
      t.references :order_service_status, foreign_key: true, index: true
      t.references :client, index: true, foreign_key: { to_table: :users }
      t.references :manager, index: true, foreign_key: { to_table: :users }
      t.references :vehicle, foreign_key: true, index: true
      t.references :provider_service_type, foreign_key: true, index: true
      t.references :maintenance_plan, foreign_key: true, index: true
      t.references :order_service_type, foreign_key: true, index: true
      t.references :provider, index: true, foreign_key: { to_table: :users }
      t.string :code
      t.integer :km
      t.string :driver
      t.text :details, :limit => 4294967295
      t.text :cancel_justification, :limit => 4294967295
      t.text :invoice_information, :limit => 4294967295

      t.decimal :invoice_part_ir, :precision => 15, :scale => 2, default: 1.2
      t.decimal :invoice_part_pis, :precision => 15, :scale => 2, default: 0.65
      t.decimal :invoice_part_cofins, :precision => 15, :scale => 2, default: 3
      t.decimal :invoice_part_csll, :precision => 15, :scale => 2, default: 1

      t.decimal :invoice_service_ir, :precision => 15, :scale => 2, default: 4.8
      t.decimal :invoice_service_pis, :precision => 15, :scale => 2, default: 0.65
      t.decimal :invoice_service_cofins, :precision => 15, :scale => 2, default: 3
      t.decimal :invoice_service_csll, :precision => 15, :scale => 2, default: 1

      t.timestamps
    end
  end
end
