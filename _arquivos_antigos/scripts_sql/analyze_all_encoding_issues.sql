-- Análise completa de problemas de encoding em todo o banco de dados

-- Padrões de encoding errado comuns:
-- ó → ó (ex: Póblico → Público)
-- ã → ã (ex: Servião → Serviço, Aperfeiãoamento → Aperfeiçoamento)
-- ú → ú (ex: Saóde → Saúde)
-- ç → ç (ex: Farmócia → Farmácia)

-- ======================
-- CIDADES
-- ======================
SELECT 'CIDADES COM ENCODING ERRADO' AS tipo;
SELECT id, name FROM cities 
WHERE name LIKE '%ó%' 
   OR name LIKE '%ã%' 
   OR name LIKE '%ó%'
   OR name LIKE '%ç%'
   OR name LIKE '%á%'
   OR name LIKE '%ê%'
   OR name LIKE '%õ%'
   OR name LIKE '%í%'
   OR name LIKE '%aul%'
LIMIT 50;

-- ======================
-- CLIENTES
-- ======================
SELECT 'CLIENTES COM ENCODING ERRADO' AS tipo;
SELECT id, name, fantasy_name FROM clients 
WHERE name LIKE '%ó%' 
   OR name LIKE '%ã%' 
   OR name LIKE '%ó%'
   OR name LIKE '%ç%'
   OR fantasy_name LIKE '%ó%'
   OR fantasy_name LIKE '%ã%'
   OR fantasy_name LIKE '%ó%'
   OR fantasy_name LIKE '%ç%'
LIMIT 50;

-- ======================
-- CENTROS DE CUSTO
-- ======================
SELECT 'CENTROS DE CUSTO COM ENCODING ERRADO' AS tipo;
SELECT id, name FROM cost_centers 
WHERE name LIKE '%ó%' 
   OR name LIKE '%ã%' 
   OR name LIKE '%ó%'
   OR name LIKE '%ç%'
LIMIT 50;

-- ======================
-- SUBUNIDADES
-- ======================
SELECT 'SUBUNIDADES COM ENCODING ERRADO' AS tipo;
SELECT id, name FROM sub_units 
WHERE name LIKE '%ó%' 
   OR name LIKE '%ã%' 
   OR name LIKE '%ó%'
   OR name LIKE '%ç%'
LIMIT 50;

-- ======================
-- USUÁRIOS
-- ======================
SELECT 'USUÁRIOS COM ENCODING ERRADO' AS tipo;
SELECT id, name, email FROM users 
WHERE name LIKE '%ó%' 
   OR name LIKE '%ã%' 
   OR name LIKE '%ó%'
   OR name LIKE '%ç%'
LIMIT 50;

-- ======================
-- FORNECEDORES (PROVIDERS)
-- ======================
SELECT 'FORNECEDORES COM ENCODING ERRADO' AS tipo;
SELECT u.id, u.name, u.fantasy_name FROM users u
JOIN user_types ut ON u.user_type_id = ut.id
WHERE ut.slug = 'provider'
  AND (u.name LIKE '%ó%' 
   OR u.name LIKE '%ã%' 
   OR u.name LIKE '%ó%'
   OR u.name LIKE '%ç%'
   OR u.fantasy_name LIKE '%ó%'
   OR u.fantasy_name LIKE '%ã%')
LIMIT 50;

-- ======================
-- VEÍCULOS
-- ======================
SELECT 'VEÍCULOS COM ENCODING ERRADO' AS tipo;
SELECT id, board, brand, model, model_text FROM vehicles 
WHERE brand LIKE '%ó%' 
   OR brand LIKE '%ã%'
   OR model LIKE '%ó%' 
   OR model LIKE '%ã%'
   OR model_text LIKE '%ó%'
   OR model_text LIKE '%ã%'
LIMIT 50;

-- ======================
-- CONTAGEM TOTAL
-- ======================
SELECT 'RESUMO GERAL' AS tipo;
SELECT 
  (SELECT COUNT(*) FROM cities WHERE name REGEXP 'ó|ã|ó|ç|á|ê|õ|í') as cidades_problemas,
  (SELECT COUNT(*) FROM clients WHERE name REGEXP 'ó|ã|ó|ç' OR fantasy_name REGEXP 'ó|ã|ó|ç') as clientes_problemas,
  (SELECT COUNT(*) FROM cost_centers WHERE name REGEXP 'ó|ã|ó|ç') as centros_custo_problemas,
  (SELECT COUNT(*) FROM sub_units WHERE name REGEXP 'ó|ã|ó|ç') as subunidades_problemas,
  (SELECT COUNT(*) FROM users WHERE name REGEXP 'ó|ã|ó|ç') as usuarios_problemas,
  (SELECT COUNT(*) FROM vehicles WHERE brand REGEXP 'ó|ã' OR model REGEXP 'ó|ã' OR model_text REGEXP 'ó|ã') as veiculos_problemas;
