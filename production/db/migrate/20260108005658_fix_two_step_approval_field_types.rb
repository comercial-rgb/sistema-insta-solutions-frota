class FixTwoStepApprovalFieldTypes < ActiveRecord::Migration[7.1]
  def up
    # Alterar tipo das colunas de int para bigint
    change_column :order_service_proposals, :approved_by_additional_id, :bigint
    change_column :order_service_proposals, :authorized_by_additional_id, :bigint
    
    # Foreign keys já foram adicionadas na migration anterior
    # add_foreign_key :order_service_proposals, :users, column: :approved_by_additional_id
    # add_foreign_key :order_service_proposals, :users, column: :authorized_by_additional_id
    
    # Índices já foram adicionados na migration anterior
    # add_index :order_service_proposals, :approved_by_additional_id
    # add_index :order_service_proposals, :authorized_by_additional_id
    # add_index :order_service_proposals, :pending_manager_approval
    # add_index :order_service_proposals, :pending_manager_authorization
  end

  def down
    # Remover índices
    remove_index :order_service_proposals, :pending_manager_authorization
    remove_index :order_service_proposals, :pending_manager_approval
    remove_index :order_service_proposals, :authorized_by_additional_id
    remove_index :order_service_proposals, :approved_by_additional_id
    
    # Remover foreign keys
    remove_foreign_key :order_service_proposals, column: :authorized_by_additional_id
    remove_foreign_key :order_service_proposals, column: :approved_by_additional_id
    
    # Voltar colunas para int
    change_column :order_service_proposals, :authorized_by_additional_id, :integer
    change_column :order_service_proposals, :approved_by_additional_id, :integer
  end
end
