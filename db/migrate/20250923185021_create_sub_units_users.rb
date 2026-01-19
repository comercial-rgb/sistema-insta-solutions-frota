class CreateSubUnitsUsers < ActiveRecord::Migration[7.1]
  def change
    create_join_table :sub_units, :users
  end
end
