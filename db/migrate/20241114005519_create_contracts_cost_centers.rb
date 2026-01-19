class CreateContractsCostCenters < ActiveRecord::Migration[7.1]
  def change
    create_join_table :contracts, :cost_centers
  end
end
