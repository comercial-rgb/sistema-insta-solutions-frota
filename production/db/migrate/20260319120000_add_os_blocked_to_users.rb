class AddOsBlockedToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :os_blocked, :boolean, default: false, null: false
  end
end
