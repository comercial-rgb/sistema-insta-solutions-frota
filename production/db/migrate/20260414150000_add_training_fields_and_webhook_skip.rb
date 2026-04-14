class AddTrainingFieldsAndWebhookSkip < ActiveRecord::Migration[5.1]
  def change
    # Training fields for clients and suppliers
    add_column :users, :training_completed, :boolean, default: false, null: false
    add_column :users, :training_date, :date
    add_column :users, :training_participants, :text
    add_column :users, :training_location, :string
    add_column :users, :training_notes, :text
    add_column :users, :training_declined, :boolean, default: false, null: false
    add_column :users, :training_declined_at, :datetime

    # Webhook skip fields
    add_column :webhook_logs, :skipped_at, :datetime
    add_column :webhook_logs, :skipped_reason, :string
  end
end
