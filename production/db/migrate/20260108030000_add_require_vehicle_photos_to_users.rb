class AddRequireVehiclePhotosToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :require_vehicle_photos, :boolean, default: false, null: false
  end
end
