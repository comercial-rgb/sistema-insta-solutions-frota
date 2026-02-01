-- 1. CORRIGIR ENCODING DO STATUS
UPDATE order_service_statuses 
SET name = 'Aguardando avaliação de proposta'
WHERE id = 2;

-- 2. VERIFICAR SE HÁ MAIS PROBLEMAS DE ENCODING
