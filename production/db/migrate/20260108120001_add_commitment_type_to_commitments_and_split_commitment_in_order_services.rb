class AddCommitmentTypeToCommitmentsAndSplitCommitmentInOrderServices < ActiveRecord::Migration[7.1]
  def change
    # Adicionar category_id na tabela commitments para diferenciar Peças (1) e Serviços (2)
    add_reference :commitments, :category, foreign_key: true
    
    # Adicionar duas colunas na order_services para referenciar dois empenhos distintos
    add_column :order_services, :commitment_parts_id, :bigint
    add_column :order_services, :commitment_services_id, :bigint
    
    # Adicionar foreign keys
    add_foreign_key :order_services, :commitments, column: :commitment_parts_id
    add_foreign_key :order_services, :commitments, column: :commitment_services_id
    
    # Migrar dados existentes: copiar commitment_id para commitment_parts_id
    # (assumindo que commitments existentes são de peças)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE order_services 
          SET commitment_parts_id = commitment_id 
          WHERE commitment_id IS NOT NULL
        SQL
      end
    end
    
    # Não remover commitment_id ainda, pois pode ser necessário manter por compatibilidade
    # Se desejar remover futuramente:
    # remove_column :order_services, :commitment_id
  end
end
