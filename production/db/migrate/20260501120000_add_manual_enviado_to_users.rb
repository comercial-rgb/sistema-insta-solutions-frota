class AddManualEnviadoToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :manual_enviado, :boolean, default: false, null: false
    add_column :users, :manual_enviado_at, :datetime
  end
end
