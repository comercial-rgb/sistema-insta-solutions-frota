class CreateCostCentersUsers < ActiveRecord::Migration[7.1]
  def change
    create_join_table :cost_centers, :users
  end
end
