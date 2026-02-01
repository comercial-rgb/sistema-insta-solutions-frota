class CreateOrderServiceInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_invoices do |t|
      t.references :order_service_proposal, foreign_key: true, index: true
      t.references :order_service_invoice_type, foreign_key: true, index: true
      t.string :number
      t.decimal :value, :precision => 15, :scale => 2
      t.date :emission_date

      t.timestamps
    end
  end
end
