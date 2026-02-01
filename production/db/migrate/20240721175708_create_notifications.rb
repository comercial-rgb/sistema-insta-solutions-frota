class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :profile, foreign_key: true, index: true
      t.boolean :send_all, default: true
      t.string :title
      t.text :message, :limit => 4294967295

      t.timestamps
    end
  end
end
