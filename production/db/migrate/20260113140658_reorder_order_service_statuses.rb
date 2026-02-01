class ReorderOrderServiceStatuses < ActiveRecord::Migration[7.1]
  def up
    # Criar novo status "Aguardando aprovação de complemento" com ID 11
    # Ordem desejada: 4-Aguardando avaliação de proposta, 11-Aguardando aprovação de complemento, 5-Aprovada
    execute <<-SQL
      INSERT INTO order_service_statuses (id, name, created_at, updated_at)
      VALUES (11, 'Aguardando aprovação de complemento', NOW(), NOW())
    SQL
  end

  def down
    execute "DELETE FROM order_service_statuses WHERE id = 11"
  end
end
