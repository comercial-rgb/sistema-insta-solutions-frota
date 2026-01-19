class AddReavaliacaoStatusAndComplementFields < ActiveRecord::Migration[7.1]
  def up
    # Status "Em reavaliação" agora é criado pelo seed com IDs fixos
    # Mantido para compatibilidade com migrações antigas
    unless OrderServiceStatus.exists?(name: 'Em reavaliação')
      execute "INSERT INTO order_service_statuses (id, name, created_at, updated_at) VALUES (3, 'Em reavaliação', NOW(), NOW())"
    end
    
    # Adicionar novo status de Aguardando aprovação de complemento para Order Service Proposals (ID 11)
    execute "INSERT INTO order_service_proposal_statuses (id, name, created_at, updated_at) VALUES (11, 'Aguardando aprovação de complemento', NOW(), NOW())"
    
    # Adicionar campo is_complement para identificar itens de complemento nas propostas
    add_column :order_service_proposal_items, :is_complement, :boolean, default: false
    
    # Adicionar campo is_complement para provider_service_temps
    add_column :provider_service_temps, :is_complement, :boolean, default: false
    
    # Adicionar campo para armazenar a proposta original (para complementos)
    add_column :order_service_proposals, :parent_proposal_id, :bigint
    add_index :order_service_proposals, :parent_proposal_id
    add_foreign_key :order_service_proposals, :order_service_proposals, column: :parent_proposal_id, on_delete: :nullify
    
    # Adicionar campo para indicar se é uma proposta de complemento
    add_column :order_service_proposals, :is_complement, :boolean, default: false
    
    # Adicionar campo para data de solicitação de reavaliação
    add_column :order_services, :reevaluation_requested_at, :datetime
    add_column :order_services, :reevaluation_requested_by_id, :bigint
    add_index :order_services, :reevaluation_requested_by_id
    add_foreign_key :order_services, :users, column: :reevaluation_requested_by_id, on_delete: :nullify
  end
  
  def down
    remove_foreign_key :order_services, column: :reevaluation_requested_by_id
    remove_index :order_services, :reevaluation_requested_by_id
    remove_column :order_services, :reevaluation_requested_by_id
    remove_column :order_services, :reevaluation_requested_at
    
    remove_column :order_service_proposals, :is_complement
    
    remove_foreign_key :order_service_proposals, column: :parent_proposal_id
    remove_index :order_service_proposals, :parent_proposal_id
    remove_column :order_service_proposals, :parent_proposal_id
    
    remove_column :provider_service_temps, :is_complement
    remove_column :order_service_proposal_items, :is_complement
    
    execute "DELETE FROM order_service_proposal_statuses WHERE id = 11"
    execute "DELETE FROM order_service_statuses WHERE name = 'Em reavaliação'"
  end
end
