class CreateAnomalies < ActiveRecord::Migration[6.1]
  def change
    create_table :anomalies do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :client, foreign_key: { to_table: :users }
      t.references :cost_center, foreign_key: true
      t.string :title, null: false
      t.text :description, size: :long
      t.string :severity, default: 'medium' # low, medium, high, critical
      t.string :status, default: 'open'     # open, in_progress, resolved, closed
      t.string :category                     # mecanica, eletrica, pneus, carroceria, etc
      t.datetime :resolved_at
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.text :resolution_notes
      t.timestamps
    end

    add_index :anomalies, :status
    add_index :anomalies, :severity
  end
end
