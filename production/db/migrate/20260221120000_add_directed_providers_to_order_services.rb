class AddDirectedProvidersToOrderServices < ActiveRecord::Migration[7.1]
  def change
    # Flag para indicar se a OS é direcionada a fornecedores específicos
    add_column :order_services, :directed_to_specific_providers, :boolean, default: false

    # Tabela de associação: quais fornecedores específicos podem ver a OS
    create_table :order_service_directed_providers, id: false do |t|
      t.bigint :order_service_id, null: false
      t.bigint :provider_id, null: false
    end

    add_index :order_service_directed_providers, [:order_service_id, :provider_id],
              unique: true, name: 'idx_os_directed_providers_unique'
    add_index :order_service_directed_providers, :provider_id,
              name: 'idx_os_directed_providers_provider'
    add_foreign_key :order_service_directed_providers, :order_services
    add_foreign_key :order_service_directed_providers, :users, column: :provider_id
  end
end
