class CreateProviderServiceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :provider_service_types do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
