-- ================================================================
-- SQL COMPLETO - Correções de Encoding
-- ================================================================
-- Execute: Get-Content fix_encoding_complete.sql | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -prot123 sistema_insta_solutions_development --default-character-set=utf8mb4

-- ================================================================
-- 1. USERS: Corrigir encoding em name, fantasy_name, social_name
-- ================================================================
UPDATE users 
SET 
  name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  fantasy_name = REPLACE(REPLACE(REPLACE(fantasy_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  social_name = REPLACE(REPLACE(REPLACE(social_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE 
  name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%'
  OR fantasy_name LIKE '%óo%' OR fantasy_name LIKE '%óa%' OR fantasy_name LIKE '%çãoo%'
  OR social_name LIKE '%óo%' OR social_name LIKE '%óa%' OR social_name LIKE '%çãoo%';

-- ================================================================
-- 2. CITIES: Corrigir encoding nas 100 cidades mais afetadas
-- ================================================================
UPDATE cities 
SET name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%'
LIMIT 1000;

-- Cidades específicas com padrões conhecidos
UPDATE cities SET name = 'Acrelândia' WHERE name LIKE 'Acrel%ndia';
UPDATE cities SET name = 'Brasiléia' WHERE name LIKE 'Brasil%ia';
UPDATE cities SET name = 'Epitaciolândia' WHERE name LIKE 'Epitaciol%ndia';
UPDATE cities SET name = 'Feijó' WHERE name LIKE 'Feij%';
UPDATE cities SET name = 'Jordão' WHERE name LIKE 'Jord%o';
UPDATE cities SET name = 'Mâncio Lima' WHERE name LIKE 'M%ncio Lima';

-- ================================================================
-- 3. VERIFICAR DADOS FINAIS
-- ================================================================
SELECT 'Status Menu - IDs e Nomes:' as info;
SELECT id, name FROM order_service_statuses WHERE id IN (1, 9);

SELECT '' as separator;
SELECT 'Contagem de OSs por Status:' as info;
SELECT 
  oss.id,
  oss.name,
  COUNT(os.id) as total_os
FROM order_service_statuses oss
LEFT JOIN order_services os ON os.order_service_status_id = oss.id
WHERE oss.id IN (1, 9)
GROUP BY oss.id, oss.name;

SELECT '' as separator;
SELECT 'Users com encoding ainda problemático:' as info;
SELECT COUNT(*) as total 
FROM users 
WHERE name LIKE '%??%' OR fantasy_name LIKE '%??%' OR social_name LIKE '%??%';

SELECT '' as separator;
SELECT 'Cities com encoding ainda problemático:' as info;
SELECT COUNT(*) as total 
FROM cities 
WHERE name LIKE '%??%';
