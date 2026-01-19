class VehicleSerializer < ActiveModel::Serializer
  attributes :id, :board, :brand, :model, :year, :color, :renavam, :chassi, :market_value, :acquisition_date, :active
  has_one :client
  has_one :cost_center
  has_one :sub_unit
  has_one :vehicle_type
  has_one :category
  has_one :state
  has_one :city
  has_one :fuel_type
end
