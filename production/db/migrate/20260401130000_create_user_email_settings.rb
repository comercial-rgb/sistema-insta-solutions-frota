class CreateUserEmailSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :user_email_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :sector, comment: 'Setor responsável (ex: Financeiro, Operacional, Diretoria)'
      t.string :description, comment: 'Descrição livre do propósito deste e-mail'
      t.boolean :receive_os_notifications, default: false, comment: 'Receber notificações de OS'
      t.boolean :receive_invoice_notifications, default: false, comment: 'Receber notificações de faturas'
      t.boolean :receive_payment_notifications, default: false, comment: 'Receber notificações de pagamentos'
      t.boolean :receive_approval_notifications, default: false, comment: 'Receber notificações de aprovações'
      t.boolean :receive_report_notifications, default: false, comment: 'Receber relatórios periódicos'
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :user_email_settings, [:user_id, :email], unique: true
  end
end
