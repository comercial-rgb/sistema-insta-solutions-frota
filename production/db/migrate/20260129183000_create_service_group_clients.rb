class CreateServiceGroupClients < ActiveRecord::Migration[7.1]
  def change
    create_table :service_group_clients do |t|
      t.bigint :service_group_id, null: false
      t.bigint :client_id, null: false

      t.timestamps
    end

    add_index :service_group_clients, [:service_group_id, :client_id], unique: true, name: 'index_sg_clients_unique'
    add_index :service_group_clients, :service_group_id
    add_index :service_group_clients, :client_id
  end
end
