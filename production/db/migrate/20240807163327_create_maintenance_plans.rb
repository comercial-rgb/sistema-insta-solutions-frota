class CreateMaintenancePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :maintenance_plans do |t|
      t.string :name

      t.timestamps
    end
  end
end
