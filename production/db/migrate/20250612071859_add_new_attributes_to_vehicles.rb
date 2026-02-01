class AddNewAttributesToVehicles < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicles, :engine_displacement, :string
    add_column :vehicles, :gearbox_type, :string
    add_column :vehicles, :fipe_code, :string
    add_column :vehicles, :model_text, :string
    add_column :vehicles, :value_text, :string
  end
end
