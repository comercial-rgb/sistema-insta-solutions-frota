class FixInconsistentOsStatusWhereProposalApproved < ActiveRecord::Migration[5.1]
  # Corrige OSs que estão em AGUARDANDO_AVALIACAO mas possuem proposta APROVADA.
  # Causa: bug na transação de aprovação onde update_all na OS falhou silenciosamente.
  def up
    # Proposal status APROVADA_ID = 3, OS status AGUARDANDO_AVALIACAO_PROPOSTA_ID = 2, APROVADA_ID = 3
    inconsistent_os_ids = execute(<<-SQL.squish).values.flatten
      SELECT DISTINCT os.id
      FROM order_services os
      INNER JOIN order_service_proposals osp ON osp.order_service_id = os.id
        AND osp.order_service_proposal_status_id = 3
        AND (osp.is_complement IS NULL OR osp.is_complement = FALSE)
      WHERE os.order_service_status_id = 2
    SQL

    return if inconsistent_os_ids.empty?

    say "Corrigindo #{inconsistent_os_ids.size} OS(s) com proposta APROVADA mas status AGUARDANDO_AVALIACAO: IDs #{inconsistent_os_ids.join(', ')}"

    execute(<<-SQL.squish)
      UPDATE order_services
      SET order_service_status_id = 3, updated_at = NOW()
      WHERE id IN (#{inconsistent_os_ids.join(',')})
    SQL
  end

  def down
    # Irreversível: não é possível saber qual era o status anterior sem o histórico
    raise ActiveRecord::IrreversibleMigration
  end
end
