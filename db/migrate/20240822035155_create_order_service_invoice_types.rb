class CreateOrderServiceInvoiceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_invoice_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
