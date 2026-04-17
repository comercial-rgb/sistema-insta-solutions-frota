class RenameProviderToClientInFaturas < ActiveRecord::Migration[7.1]
  def change
    rename_column :faturas, :provider_id, :client_id
  end
end
