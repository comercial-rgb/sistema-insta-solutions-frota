class AddDriverProfileAndFields < ActiveRecord::Migration[7.0]
  def up
    # Criar perfil Motorista (ID 7)
    execute "INSERT INTO profiles (id, name, created_at, updated_at) VALUES (7, 'Motorista', NOW(), NOW())" unless Profile.exists?(7)

    # Campos do motorista na tabela users
    add_column :users, :cnh_number, :string unless column_exists?(:users, :cnh_number)
    add_column :users, :cnh_category, :string unless column_exists?(:users, :cnh_category)
    add_column :users, :cnh_expiration, :date unless column_exists?(:users, :cnh_expiration)
    add_column :users, :cnh_issued_at, :date unless column_exists?(:users, :cnh_issued_at)

    add_index :users, :cnh_number, unique: true, where: "cnh_number IS NOT NULL AND cnh_number != ''" unless index_exists?(:users, :cnh_number)
  end

  def down
    remove_index :users, :cnh_number if index_exists?(:users, :cnh_number)
    remove_column :users, :cnh_issued_at if column_exists?(:users, :cnh_issued_at)
    remove_column :users, :cnh_expiration if column_exists?(:users, :cnh_expiration)
    remove_column :users, :cnh_category if column_exists?(:users, :cnh_category)
    remove_column :users, :cnh_number if column_exists?(:users, :cnh_number)

    execute "DELETE FROM profiles WHERE id = 7"
  end
end
