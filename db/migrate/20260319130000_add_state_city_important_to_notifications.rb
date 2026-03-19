class AddStateCityImportantToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_reference :notifications, :state, foreign_key: true, null: true
    add_reference :notifications, :city, foreign_key: true, null: true
    add_column :notifications, :is_important, :boolean, default: false, null: false
  end
end
