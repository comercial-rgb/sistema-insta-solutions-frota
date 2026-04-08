class CreateSupportTickets < ActiveRecord::Migration[5.1]
  def change
    create_table :support_tickets do |t|
      t.references :user, index: true, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :ticket_type, default: 0, null: false
      # 0 = bug, 1 = melhoria, 2 = suporte
      t.integer :criticality, default: 0, null: false
      # 0 = baixa, 1 = média, 2 = alta, 3 = crítica
      t.integer :status, default: 0, null: false
      # 0 = aberto, 1 = em_andamento, 2 = resolvido, 3 = fechado
      t.references :resolved_by, index: true, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :support_tickets, :status
    add_index :support_tickets, :ticket_type
    add_index :support_tickets, :criticality

    create_table :support_ticket_messages do |t|
      t.references :support_ticket, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
