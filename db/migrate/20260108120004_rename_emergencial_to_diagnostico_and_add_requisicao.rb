class RenameEmergencialToDiagnosticoAndAddRequisicao < ActiveRecord::Migration[7.1]
  def up
    # Renomear "Emergencial" para "Diagnóstico" (id = 2)
    execute "UPDATE order_service_types SET name = 'Diagnóstico' WHERE id = 2"
    
    # Criar novo tipo "Requisição" (id = 3)
    execute "INSERT INTO order_service_types (id, name, created_at, updated_at) VALUES (3, 'Requisição', NOW(), NOW())"
  end

  def down
    # Reverter: Diagnóstico volta a ser Emergencial
    execute "UPDATE order_service_types SET name = 'Emergencial' WHERE id = 2"
    
    # Remover tipo Requisição
    execute "DELETE FROM order_service_types WHERE id = 3"
  end
end
