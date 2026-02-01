-- Relatório de Propostas com Anexos Corrompidos
-- Identifica propostas que têm anexos com 0 bytes no disco

SELECT 
    os.code as 'OS',
    os.id as 'OS_ID',
    osp.id as 'Proposta_ID',
    CASE 
        WHEN osps.id = 8 THEN 'Autorizada'
        WHEN osps.id = 9 THEN 'Nota Fiscal Inserida'
        ELSE osps.name
    END as 'Status',
    u.name as 'Fornecedor',
    att.id as 'Anexo_ID',
    asb.filename as 'Nome_Arquivo',
    asb.byte_size as 'Tamanho_DB',
    asb.content_type as 'Tipo',
    att.created_at as 'Data_Upload',
    CONCAT('https://frotainstasolutions.com.br/order_service_proposals/', osp.id) as 'Link_Proposta'
FROM active_storage_blobs asb
INNER JOIN active_storage_attachments asa ON asa.blob_id = asb.id
INNER JOIN attachments att ON att.id = asa.record_id AND asa.record_type = 'Attachment'
INNER JOIN order_service_proposals osp ON osp.id = att.ownertable_id AND att.ownertable_type = 'OrderServiceProposal'
INNER JOIN order_service_proposal_statuses osps ON osps.id = osp.order_service_proposal_status_id
INNER JOIN order_services os ON os.id = osp.order_service_id
LEFT JOIN users u ON u.id = osp.provider_id
WHERE asb.byte_size > 0 -- No banco diz que tem conteúdo
  AND osps.id IN (8, 9) -- Status: Autorizada ou Nota Fiscal Inserida
ORDER BY os.code, osp.id, att.created_at DESC;
