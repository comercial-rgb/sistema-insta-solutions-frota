class CostCenterSerializer < ActiveModel::Serializer
  attributes :id, :name, :contract_number, :commitment_number, :initial_consumed_balance, :description, :budget_value, :contract_initial_date, :has_sub_units
  has_one :client
  has_one :budget_type
end
