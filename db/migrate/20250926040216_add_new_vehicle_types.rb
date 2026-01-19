class AddNewVehicleTypes < ActiveRecord::Migration[7.1]
  def change
    VehicleType.create([
      {name: "Vans / Furgões"},
      {name: "Caminhões"},
      {name: "Motocicleta"}
    ])
  end
end
