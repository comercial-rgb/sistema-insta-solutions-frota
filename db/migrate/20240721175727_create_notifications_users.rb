class CreateNotificationsUsers < ActiveRecord::Migration[7.1]
  def change
    create_join_table :notifications, :users
  end
end
