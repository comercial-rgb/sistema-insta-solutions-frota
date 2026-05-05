class FixInconsistentOsStatusWhereProposalApproved < ActiveRecord::Migration[5.1]
  # Corrige OSs que estão em AGUARDANDO_AVALIACAO mas possuem proposta APROVADA.
  # Causa: bug na transação de aprovação onde update_all na OS falhou silenciosamente.
  def up
    # proposal_status APROVADA_ID = 3, os_status AGUARDANDO_AVALIACAO = 2, APROVADA = 3
    result = ActiveRecord::Base.connection.execute(<<-SQL.squish)
      SELECT DISTINCT os.id
      FROM order_services os
      INNER JOIN order_service_proposals osp ON osp.order_service_id = os.id
        AND osp.order_service_proposal_status_id = 3
        AND (osp.is_complement IS NULL OR osp.is_complement = 0)
      WHERE os.order_service_status_id = 2
    SQL

    inconsistent_os_ids = result.map { |row| row.is_a?(Hash) ? row['id'] : row[0] }.compact

    return if inconsistent_os_ids.empty?

    say "Corrigindo #{inconsistent_os_ids.size} OS(s): IDs #{inconsistent_os_ids.join(', ')}"

    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      UPDATE order_services
      SET order_service_status_id = 3, updated_at = NOW()
      WHERE id IN (#{inconsistent_os_ids.join(',')})
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
