class CreateCommitmentCostCenters < ActiveRecord::Migration[7.1]
  def change
    create_table :commitment_cost_centers do |t|
      t.references :commitment, null: false, foreign_key: true
      t.references :cost_center, null: false, foreign_key: true

      t.timestamps
    end

    # Adiciona índice único para evitar duplicatas
    add_index :commitment_cost_centers, [:commitment_id, :cost_center_id], unique: true, name: 'index_commitment_cost_centers_unique'

    # Migra dados existentes da coluna cost_center_id para a nova tabela de relacionamento
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO commitment_cost_centers (commitment_id, cost_center_id, created_at, updated_at)
          SELECT id, cost_center_id, NOW(), NOW()
          FROM commitments
          WHERE cost_center_id IS NOT NULL
        SQL
      end
    end
  end
end
