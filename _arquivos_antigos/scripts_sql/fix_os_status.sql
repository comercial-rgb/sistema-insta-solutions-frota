-- Script SQL para corrigir status de OS que tem proposta aprovada mas não foi atualizada

-- 1. Primeiro, vamos ver todas as OSs problemáticas
SELECT 
    os.id as os_id,
    os.code as os_code,
    os.order_service_status_id as os_status_atual,
    oss.name as os_status_nome,
    osp.id as proposta_id,
    osp.code as proposta_code,
    osp.order_service_proposal_status_id as proposta_status,
    osps.name as proposta_status_nome
FROM order_services os
INNER JOIN order_service_proposals osp ON osp.order_service_id = os.id
INNER JOIN order_service_statuses oss ON oss.id = os.order_service_status_id
INNER JOIN order_service_proposal_statuses osps ON osps.id = osp.order_service_proposal_status_id
WHERE osp.order_service_proposal_status_id = 3  -- Proposta Aprovada
  AND os.order_service_status_id != 5;          -- OS NÃO está Aprovada

-- 2. Corrigir a OS6805722026112 especificamente
UPDATE order_services 
SET order_service_status_id = 5 
WHERE code = 'OS6805722026112' 
  AND order_service_status_id != 5;

-- 3. Verificar a correção
SELECT 
    os.id,
    os.code,
    os.order_service_status_id,
    oss.name as status_nome
FROM order_services os
INNER JOIN order_service_statuses oss ON oss.id = os.order_service_status_id
WHERE os.code = 'OS6805722026112';

-- 4. (OPCIONAL) Se quiser corrigir TODAS as OSs com esse problema, descomente:
-- UPDATE order_services os
-- INNER JOIN order_service_proposals osp ON osp.order_service_id = os.id
-- SET os.order_service_status_id = 5
-- WHERE osp.order_service_proposal_status_id = 3
--   AND os.order_service_status_id != 5;
