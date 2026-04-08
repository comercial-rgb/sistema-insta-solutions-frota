class AddQrNfcEnabledToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :qr_nfc_enabled, :boolean, default: false, null: false
    add_column :users, :qr_code_token, :string
    add_index :users, :qr_code_token, unique: true
  end
end
