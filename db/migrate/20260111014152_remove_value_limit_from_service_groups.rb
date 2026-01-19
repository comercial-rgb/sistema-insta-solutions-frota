class RemoveValueLimitFromServiceGroups < ActiveRecord::Migration[7.1]
  def change
    remove_column :service_groups, :value_limit, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
