-- Script de correção completa de encoding
-- Executar em produção

-- ======================
-- VEÍCULOS
-- ======================

-- MARRUÁ (caminhão)
UPDATE vehicles SET model = REPLACE(model, 'MARRU??', 'MARRUÁ') WHERE model LIKE '%MARRU??%';
UPDATE vehicles SET model_text = REPLACE(model_text, 'MARRU??', 'MARRUÁ') WHERE model_text LIKE '%MARRU??%';

-- FURGÃO
UPDATE vehicles SET model_text = REPLACE(model_text, 'Furg??o', 'Furgão') WHERE model_text LIKE '%Furg??o%';

-- MÉDIO
UPDATE vehicles SET model_text = REPLACE(model_text, 'm??d', 'méd') WHERE model_text LIKE '%m??d%';

-- PÁ CARREGADEIRA
UPDATE vehicles SET model = REPLACE(model, 'P??', 'PÁ') WHERE model LIKE '%P??%';

-- ROÇADEIRA
UPDATE vehicles SET model = REPLACE(model, 'RO??ADEIRA', 'ROÇADEIRA') WHERE model LIKE '%RO??ADEIRA%';

-- ======================
-- MOTORISTAS
-- ======================

-- CÁSSIO
UPDATE order_services SET driver = REPLACE(driver, 'C??ssio', 'Cássio') WHERE driver LIKE '%C??ssio%';

-- JOSÉ
UPDATE order_services SET driver = REPLACE(driver, 'Jos??', 'José') WHERE driver LIKE '%Jos??%';

-- ANDRÉ
UPDATE order_services SET driver = REPLACE(driver, 'Andr??', 'André') WHERE driver LIKE '%Andr??%';

-- ======================
-- CIDADES - ESPERANÇA
-- ======================

-- Esperança (todas variações)
UPDATE cities SET name = REPLACE(name, 'Esperançã', 'Esperança') WHERE name LIKE '%Esperançã%';

-- Iguaçu
UPDATE cities SET name = REPLACE(name, 'Iguaçul', 'Iguaçu') WHERE name LIKE '%Iguaçul%';

-- Piriá
UPDATE cities SET name = REPLACE(name, 'Piriã', 'Piriá') WHERE name LIKE '%Piriã%';

-- ======================
-- VERIFICAÇÃO FINAL
-- ======================

SELECT 'VEICULOS RESTANTES COM ??' AS status, COUNT(*) as total FROM vehicles WHERE model LIKE '%??%' OR model_text LIKE '%??%';
SELECT 'MOTORISTAS RESTANTES COM ??' AS status, COUNT(*) as total FROM order_services WHERE driver LIKE '%??%';
SELECT 'CIDADES RESTANTES COM ??' AS status, COUNT(*) as total FROM cities WHERE name LIKE '%??%';

-- Mostrar exemplos corrigidos
SELECT 'EXEMPLOS CORRIGIDOS - VEÍCULOS' AS tipo;
SELECT id, model, model_text FROM vehicles WHERE model LIKE '%MARRUÁ%' OR model_text LIKE '%Furgão%' LIMIT 5;

SELECT 'EXEMPLOS CORRIGIDOS - MOTORISTAS' AS tipo;
SELECT DISTINCT driver FROM order_services WHERE driver LIKE '%Cássio%' OR driver LIKE '%José%' OR driver LIKE '%André%' LIMIT 5;

SELECT 'EXEMPLOS CORRIGIDOS - CIDADES' AS tipo;
SELECT id, name FROM cities WHERE name LIKE '%Esperança%' LIMIT 10;

SELECT '✅ CORREÇÃO DE ENCODING CONCLUÍDA!' AS resultado;
