class CreateOrderServiceProposals < ActiveRecord::Migration[7.1]
  def change
    create_table :order_service_proposals do |t|
      t.references :order_service, foreign_key: true, index: true
      t.references :provider, index: true, foreign_key: { to_table: :users }
      t.references :order_service_proposal_status, foreign_key: true, index: true
      t.text :details, :limit => 4294967295
      t.decimal :total_value, :precision => 15, :scale => 2
      t.decimal :total_discount, :precision => 15, :scale => 2
      t.decimal :total_value_without_discount, :precision => 15, :scale => 2
      t.string :code

      t.boolean :reproved, default: false
      t.text :reason_reproved

      t.timestamps
    end
  end
end
