class CreateVehicleChecklists < ActiveRecord::Migration[7.0]
  def change
    create_table :vehicle_checklists do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, comment: 'Quem realizou o checklist'
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :cost_center, foreign_key: true
      t.integer :current_km
      t.string :status, default: 'pending', null: false, comment: 'pending/acknowledged/os_created/closed'
      t.text :general_notes
      t.datetime :acknowledged_at
      t.references :acknowledged_by, foreign_key: { to_table: :users }
      t.references :order_service, foreign_key: true, comment: 'OS gerada a partir deste checklist'

      t.timestamps
    end

    create_table :vehicle_checklist_items do |t|
      t.references :vehicle_checklist, null: false, foreign_key: true
      t.string :category, null: false, comment: 'motor/freios/pneus/eletrica/carroceria/interior/luzes/fluidos/documentacao/outros'
      t.string :item_name, null: false, comment: 'Nome do item verificado'
      t.string :condition, null: false, comment: 'ok/attention/critical/na'
      t.text :observation
      t.boolean :has_anomaly, default: false

      t.timestamps
    end

    add_index :vehicle_checklists, :status
    add_index :vehicle_checklists, :created_at
    add_index :vehicle_checklist_items, :category
    add_index :vehicle_checklist_items, :condition
    add_index :vehicle_checklist_items, :has_anomaly
  end
end
