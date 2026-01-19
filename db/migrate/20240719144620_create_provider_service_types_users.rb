class CreateProviderServiceTypesUsers < ActiveRecord::Migration[7.1]
  def change
    create_join_table :provider_service_types, :users
  end
end
