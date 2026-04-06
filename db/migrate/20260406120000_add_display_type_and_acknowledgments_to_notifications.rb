class AddDisplayTypeAndAcknowledgmentsToNotifications < ActiveRecord::Migration[6.1]
  def change
    # display_type: 0 = sino (bell only), 1 = popup, 2 = ambos (popup + bell)
    add_column :notifications, :display_type, :integer, default: 0, null: false
    # requires_acknowledgment: se true, usuário precisa clicar "Ciente"
    add_column :notifications, :requires_acknowledgment, :boolean, default: false, null: false

    # Migrar dados: is_important=true => display_type=1 (popup)
    reversible do |dir|
      dir.up do
        execute "UPDATE notifications SET display_type = 1 WHERE is_important = 1"
      end
    end

    # Tabela para registrar ciência dos usuários
    create_table :notification_acknowledgments do |t|
      t.bigint :notification_id, null: false
      t.bigint :user_id, null: false
      t.datetime :acknowledged_at, null: false
      t.timestamps
    end

    add_index :notification_acknowledgments, [:notification_id, :user_id], unique: true, name: 'idx_notif_ack_notification_user'
    add_index :notification_acknowledgments, :user_id, name: 'idx_notif_ack_user'
    add_foreign_key :notification_acknowledgments, :notifications
    add_foreign_key :notification_acknowledgments, :users
  end
end
