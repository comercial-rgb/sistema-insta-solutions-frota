class CreateSubUnits < ActiveRecord::Migration[7.1]
  def change
    create_table :sub_units do |t|
      t.references :cost_center, foreign_key: true, index: true
      t.string :name
      t.string :contract_number
      t.string :commitment_number
      t.decimal :initial_consumed_balance, :precision => 15, :scale => 2
      t.decimal :budget_value, :precision => 15, :scale => 2
      t.references :budget_type, foreign_key: true, index: true
      t.date :contract_initial_date

      t.timestamps
    end
  end
end
