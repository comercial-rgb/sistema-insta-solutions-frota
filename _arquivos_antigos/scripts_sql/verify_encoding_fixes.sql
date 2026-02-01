-- Verificação das correções de encoding

SELECT 'VERIFICAÇÃO DE ENCODING - RELATÓRIO FINAL' AS status;

SELECT '1. Veículos com LOTAÇÃO:' AS info;
SELECT COUNT(*) as total FROM vehicles WHERE model_text LIKE '%LOTAÇÃO%' OR model LIKE '%LOTAÇÃO%';

SELECT '2. Cidades corrigidas:' AS info;
SELECT name FROM cities WHERE name IN ('Esperança', 'Boqueirão', 'Osório');

SELECT '3. Motoristas corrigidos:' AS info;
SELECT DISTINCT driver FROM order_services WHERE driver IN ('Luís', 'Valério') OR driver LIKE '%Hélinton%' LIMIT 5;

SELECT '4. Registros com problemas restantes (???):' AS info;
SELECT COUNT(*) as total_problemas FROM (
  SELECT id FROM vehicles WHERE model LIKE '%??%' OR model_text LIKE '%??%'
  UNION
  SELECT id FROM cities WHERE name LIKE '%??%'
  UNION
  SELECT id FROM order_services WHERE driver LIKE '%??%'
) AS problemas;

SELECT 'VERIFICAÇÃO CONCLUÍDA!' AS status;
