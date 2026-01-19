class AddNeedsKmToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :needs_km, :boolean, default: false
  end
end
