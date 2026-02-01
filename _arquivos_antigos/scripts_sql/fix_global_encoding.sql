-- CORREÇÃO GLOBAL DE ENCODING UTF-8
-- Converte todos os caracteres mal codificados para UTF-8 correto

-- MAPEAMENTO COMPLETO DE CARACTERES:
-- ã → ã | á → á | â → â | à → à
-- ó → ó | ô → ô | õ → õ
-- ú → ú | ü → ü
-- ê → ê | é → é
-- í → í | ç → ç

-- ======================
-- CIDADES - CORREÇÃO GLOBAL
-- ======================

UPDATE cities SET name = REPLACE(name, 'ã', 'ã');
UPDATE cities SET name = REPLACE(name, 'á', 'á');  
UPDATE cities SET name = REPLACE(name, 'â', 'â');
UPDATE cities SET name = REPLACE(name, 'à', 'à');
UPDATE cities SET name = REPLACE(name, 'ó', 'ó');
UPDATE cities SET name = REPLACE(name, 'ô', 'ô');
UPDATE cities SET name = REPLACE(name, 'õ', 'õ');
UPDATE cities SET name = REPLACE(name, 'ú', 'ú');
UPDATE cities SET name = REPLACE(name, 'ü', 'ü');
UPDATE cities SET name = REPLACE(name, 'ê', 'ê');
UPDATE cities SET name = REPLACE(name, 'é', 'é');
UPDATE cities SET name = REPLACE(name, 'í', 'í');
UPDATE cities SET name = REPLACE(name, 'ç', 'ç');

-- ======================
-- USUÁRIOS - CORREÇÃO GLOBAL
-- ======================

UPDATE users SET name = REPLACE(name, 'ã', 'ã');
UPDATE users SET name = REPLACE(name, 'á', 'á');
UPDATE users SET name = REPLACE(name, 'â', 'â');
UPDATE users SET name = REPLACE(name, 'ó', 'ó');
UPDATE users SET name = REPLACE(name, 'ô', 'ô');
UPDATE users SET name = REPLACE(name, 'ú', 'ú');
UPDATE users SET name = REPLACE(name, 'ê', 'ê');
UPDATE users SET name = REPLACE(name, 'é', 'é');
UPDATE users SET name = REPLACE(name, 'í', 'í');
UPDATE users SET name = REPLACE(name, 'ç', 'ç');

UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ã', 'ã');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'á', 'á');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'â', 'â');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ó', 'ó');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ô', 'ô');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ú', 'ú');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ê', 'ê');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'é', 'é');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'í', 'í');
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'ç', 'ç');

-- ======================
-- CENTROS DE CUSTO - CORREÇÃO GLOBAL
-- ======================

UPDATE cost_centers SET name = REPLACE(name, 'ã', 'ã');
UPDATE cost_centers SET name = REPLACE(name, 'á', 'á');
UPDATE cost_centers SET name = REPLACE(name, 'ó', 'ó');
UPDATE cost_centers SET name = REPLACE(name, 'ú', 'ú');
UPDATE cost_centers SET name = REPLACE(name, 'ê', 'ê');
UPDATE cost_centers SET name = REPLACE(name, 'é', 'é');
UPDATE cost_centers SET name = REPLACE(name, 'í', 'í');
UPDATE cost_centers SET name = REPLACE(name, 'ç', 'ç');

-- ======================
-- SUBUNIDADES - CORREÇÃO GLOBAL
-- ======================

UPDATE sub_units SET name = REPLACE(name, 'ã', 'ã');
UPDATE sub_units SET name = REPLACE(name, 'á', 'á');
UPDATE sub_units SET name = REPLACE(name, 'ó', 'ó');
UPDATE sub_units SET name = REPLACE(name, 'ú', 'ú');
UPDATE sub_units SET name = REPLACE(name, 'ê', 'ê');
UPDATE sub_units SET name = REPLACE(name, 'é', 'é');
UPDATE sub_units SET name = REPLACE(name, 'í', 'í');
UPDATE sub_units SET name = REPLACE(name, 'ç', 'ç');

-- ======================
-- VEÍCULOS - CORREÇÃO GLOBAL
-- ======================

UPDATE vehicles SET brand = REPLACE(brand, 'ã', 'ã');
UPDATE vehicles SET brand = REPLACE(brand, 'ó', 'ó');
UPDATE vehicles SET brand = REPLACE(brand, 'ç', 'ç');

UPDATE vehicles SET model = REPLACE(model, 'ã', 'ã');
UPDATE vehicles SET model = REPLACE(model, 'ó', 'ó');
UPDATE vehicles SET model = REPLACE(model, 'ç', 'ç');

UPDATE vehicles SET model_text = REPLACE(model_text, 'ã', 'ã');
UPDATE vehicles SET model_text = REPLACE(model_text, 'ó', 'ó');
UPDATE vehicles SET model_text = REPLACE(model_text, 'ç', 'ç');

-- ======================
-- ORDER SERVICES - CORREÇÃO GLOBAL
-- ======================

UPDATE order_services SET driver = REPLACE(driver, 'ã', 'ã');
UPDATE order_services SET driver = REPLACE(driver, 'á', 'á');
UPDATE order_services SET driver = REPLACE(driver, 'ó', 'ó');
UPDATE order_services SET driver = REPLACE(driver, 'ú', 'ú');
UPDATE order_services SET driver = REPLACE(driver, 'ê', 'ê');
UPDATE order_services SET driver = REPLACE(driver, 'é', 'é');
UPDATE order_services SET driver = REPLACE(driver, 'í', 'í');
UPDATE order_services SET driver = REPLACE(driver, 'ç', 'ç');

-- ======================
-- VERIFICAÇÃO FINAL
-- ======================

SELECT '🔍 CONTAGEM FINAL DE PROBLEMAS' AS status;

SELECT 'Cidades' AS tabela, COUNT(*) as problemas_restantes
FROM cities 
WHERE name LIKE '%ã%' OR name LIKE '%ó%' OR name LIKE '%á%' 
   OR name LIKE '%ê%' OR name LIKE '%í%' OR name LIKE '%ç%';

SELECT 'Usuários (name)' AS tabela, COUNT(*) as problemas_restantes
FROM users 
WHERE name LIKE '%ã%' OR name LIKE '%ó%' OR name LIKE '%á%';

SELECT 'Usuários (fantasy_name)' AS tabela, COUNT(*) as problemas_restantes
FROM users 
WHERE fantasy_name LIKE '%ã%' OR fantasy_name LIKE '%ó%';

SELECT 'Centros de Custo' AS tabela, COUNT(*) as problemas_restantes
FROM cost_centers 
WHERE name LIKE '%ã%' OR name LIKE '%ó%';

SELECT 'Subunidades' AS tabela, COUNT(*) as problemas_restantes
FROM sub_units 
WHERE name LIKE '%ã%' OR name LIKE '%ó%';

SELECT 'Veículos' AS tabela, COUNT(*) as problemas_restantes
FROM vehicles 
WHERE brand LIKE '%ã%' OR brand LIKE '%ó%' 
   OR model LIKE '%ã%' OR model LIKE '%ó%'
   OR model_text LIKE '%ã%' OR model_text LIKE '%ó%';

SELECT 'Order Services (driver)' AS tabela, COUNT(*) as problemas_restantes
FROM order_services 
WHERE driver LIKE '%ã%' OR driver LIKE '%ó%';

SELECT '✅ CORREÇÃO GLOBAL DE ENCODING CONCLUÍDA!' AS resultado;
