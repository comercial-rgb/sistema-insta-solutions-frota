class CreateCostCenters < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_centers do |t|
      t.references :client, index: true, foreign_key: { to_table: :users }
      t.string :name
      t.string :contract_number
      t.string :commitment_number
      t.decimal :initial_consumed_balance, :precision => 15, :scale => 2
      t.text :description
      t.decimal :budget_value, :precision => 15, :scale => 2
      t.references :budget_type, foreign_key: true, index: true
      t.date :contract_initial_date
      t.boolean :has_sub_units

      t.string :invoice_name
      t.string :invoice_cnpj
      t.text :invoice_address
      t.references :invoice_state, index: true, foreign_key: { to_table: :states }
      t.string :invoice_fantasy_name

      t.timestamps
    end
  end
end
