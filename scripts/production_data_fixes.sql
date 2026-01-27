-- ================================================================
-- CORREÇÕES DE DADOS PARA PRODUÇÃO - Sistema Insta Solutions
-- ================================================================
-- Data: 27/01/2026
-- Objetivo: Aplicar correções de encoding e dados inconsistentes
--
-- ⚠️ IMPORTANTE:
-- 1. Fazer BACKUP completo do banco ANTES de executar
-- 2. Executar em HORÁRIO DE BAIXO MOVIMENTO
-- 3. Validar algumas amostras após cada bloco
-- ================================================================

-- Definir charset para evitar problemas
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ================================================================
-- BLOCO 1: CORREÇÕES DE MENU (OrderServiceStatus)
-- ================================================================
-- Garantir que os IDs dos status estão corretos
-- (Nenhuma alteração SQL necessária - já está no código)

-- ================================================================
-- BLOCO 2: CORREÇÕES DE ENCODING EM order_services.details
-- ================================================================
UPDATE order_services 
SET details = REPLACE(details, '??', 'ão') 
WHERE details LIKE '%??%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'lu????o', 'lução')
WHERE details LIKE '%lu????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'lubrifica????o', 'lubrificação')
WHERE details LIKE '%lubrifica????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'manuten????o', 'manutenção')
WHERE details LIKE '%manuten????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'revis??o', 'revisão')
WHERE details LIKE '%revis??o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'substitui????o', 'substituição')
WHERE details LIKE '%substitui????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'corre????o', 'correção')
WHERE details LIKE '%corre????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'verifica????o', 'verificação')
WHERE details LIKE '%verifica????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'instala????o', 'instalação')
WHERE details LIKE '%instala????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'inspe????o', 'inspeção')
WHERE details LIKE '%inspe????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'regula????o', 'regulação')
WHERE details LIKE '%regula????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'preven????o', 'prevenção')
WHERE details LIKE '%preven????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'repara????o', 'reparação')
WHERE details LIKE '%repara????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'corre????o', 'correção')
WHERE details LIKE '%corre????o%' COLLATE utf8mb4_bin;

UPDATE order_services 
SET details = REPLACE(details, 'atua????o', 'atuação')
WHERE details LIKE '%atua????o%' COLLATE utf8mb4_bin;

-- ================================================================
-- BLOCO 3: CORREÇÕES EM cost_centers (Dados de Faturamento)
-- ================================================================
UPDATE cost_centers 
SET invoice_name = REPLACE(invoice_name, 'Gest??o', 'Gestão')
WHERE invoice_name LIKE '%Gest??o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_name = REPLACE(invoice_name, 'Superintend??ncia', 'Superintendência')
WHERE invoice_name LIKE '%Superintend??ncia%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_name = REPLACE(invoice_name, 'educa????o', 'educação')
WHERE invoice_name LIKE '%educa????o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_name = REPLACE(invoice_name, 'Integra????o', 'Integração')
WHERE invoice_name LIKE '%Integra????o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_name = REPLACE(invoice_name, 'Am??rico', 'Américo')
WHERE invoice_name LIKE '%Am??rico%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_fantasy_name = REPLACE(invoice_fantasy_name, 'Gest??o', 'Gestão')
WHERE invoice_fantasy_name LIKE '%Gest??o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_fantasy_name = REPLACE(invoice_fantasy_name, 'Superintend??ncia', 'Superintendência')
WHERE invoice_fantasy_name LIKE '%Superintend??ncia%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_fantasy_name = REPLACE(invoice_fantasy_name, 'educa????o', 'educação')
WHERE invoice_fantasy_name LIKE '%educa????o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Ibira??u', 'Ibiraçu')
WHERE invoice_address LIKE '%Ibira??u%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Pra??a', 'Praça')
WHERE invoice_address LIKE '%Pra??a%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Jos??', 'José')
WHERE invoice_address LIKE '%Jos??%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Fund??o', 'Fundão')
WHERE invoice_address LIKE '%Fund??o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Banc??rio', 'Bancário')
WHERE invoice_address LIKE '%Banc??rio%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Edif??cio', 'Edifício')
WHERE invoice_address LIKE '%Edif??cio%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Vit??rio', 'Vitório')
WHERE invoice_address LIKE '%Vit??rio%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Paix??o', 'Paixão')
WHERE invoice_address LIKE '%Paix??o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Louren??o', 'Lourenço')
WHERE invoice_address LIKE '%Louren??o%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET invoice_address = REPLACE(invoice_address, 'Esp??rito', 'Espírito')
WHERE invoice_address LIKE '%Esp??rito%' COLLATE utf8mb4_bin;

-- ================================================================
-- BLOCO 4: CORREÇÕES EM order_service_invoice_types
-- ================================================================
UPDATE order_service_invoice_types 
SET name = 'Peças' 
WHERE id = 1 AND name LIKE '%Pe??as%';

UPDATE order_service_invoice_types 
SET name = 'Serviços' 
WHERE id = 2 AND name LIKE '%Servi??os%';

-- ================================================================
-- BLOCO 5: CORREÇÕES EM cost_centers.name E vehicles.model
-- ================================================================
UPDATE cost_centers 
SET name = REPLACE(name, 'óncia', 'ência')
WHERE name LIKE '%óncia%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET name = REPLACE(name, 'ónica', 'ônica')
WHERE name LIKE '%ónica%' COLLATE utf8mb4_bin;

UPDATE cost_centers 
SET name = REPLACE(name, 'ãl', 'al')
WHERE name LIKE '%ãl%' COLLATE utf8mb4_bin;

UPDATE vehicles 
SET model = REPLACE(model, 'óncia', 'ência')
WHERE model LIKE '%óncia%' COLLATE utf8mb4_bin;

UPDATE vehicles 
SET model = REPLACE(model, 'ónica', 'ônica')
WHERE model LIKE '%ónica%' COLLATE utf8mb4_bin;

-- ================================================================
-- VALIDAÇÕES (Executar após as correções)
-- ================================================================
-- Verificar se ainda existem problemas:

SELECT 'order_services.details com ??' AS check_name, COUNT(*) AS count
FROM order_services 
WHERE details LIKE '%??%' COLLATE utf8mb4_bin;

SELECT 'cost_centers.invoice_* com ??' AS check_name, COUNT(*) AS count
FROM cost_centers 
WHERE invoice_name LIKE '%??%' COLLATE utf8mb4_bin
   OR invoice_fantasy_name LIKE '%??%' COLLATE utf8mb4_bin
   OR invoice_address LIKE '%??%' COLLATE utf8mb4_bin;

SELECT 'order_service_invoice_types' AS check_name, id, name
FROM order_service_invoice_types
ORDER BY id;

-- ================================================================
-- FIM DO SCRIPT
-- ================================================================
