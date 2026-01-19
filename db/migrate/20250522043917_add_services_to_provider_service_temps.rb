class AddServicesToProviderServiceTemps < ActiveRecord::Migration[7.1]
  def change
    add_reference :provider_service_temps, :service, index: true, foreign_key: true
  end
end
