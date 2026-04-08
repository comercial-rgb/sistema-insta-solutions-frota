class CreateWebhookLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_logs do |t|
      t.references :order_service, foreign_key: true, null: false
      t.integer :status, default: 0, null: false # 0=pending, 1=success, 2=failed
      t.integer :attempts, default: 0, null: false
      t.string :last_error
      t.string :last_http_code
      t.datetime :last_attempt_at
      t.datetime :succeeded_at

      t.timestamps
    end

    add_index :webhook_logs, :status
    add_index :webhook_logs, [:order_service_id, :status], name: 'idx_webhook_logs_os_status'
  end
end
