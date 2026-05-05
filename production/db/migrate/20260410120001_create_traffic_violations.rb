class CreateTrafficViolations < ActiveRecord::Migration[7.0]
  def change
    create_table :traffic_violations do |t|
      t.references :user, null: false, foreign_key: true, comment: 'Motorista infrator'
      t.references :vehicle, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.string :auto_number, comment: 'Número do auto de infração'
      t.date :violation_date, null: false
      t.string :violation_type, comment: 'Tipo da infração (leve/media/grave/gravissima)'
      t.text :description
      t.decimal :fine_value, precision: 10, scale: 2
      t.integer :points, default: 0
      t.string :status, default: 'pending', comment: 'pending/paid/appealed/cancelled'
      t.date :due_date
      t.date :paid_at
      t.text :notes

      t.timestamps
    end

    add_index :traffic_violations, :violation_date
    add_index :traffic_violations, :status
    add_index :traffic_violations, :auto_number
  end
end
