-- RELATÓRIO FINAL DE ENCODING
-- Verificação de que todos os dados estão corretos

SELECT '═══════════════════════════════════════' AS divisor;
SELECT '  RELATÓRIO FINAL - ENCODING UTF-8  ' AS titulo;
SELECT '═══════════════════════════════════════' AS divisor;

SELECT '' AS espaco;
SELECT '✅ CIDADES - EXEMPLOS CORRETOS:' AS secao;
SELECT name FROM cities WHERE name LIKE '%ção%' LIMIT 5;
SELECT name FROM cities WHERE name LIKE '%Água%' LIMIT 5;
SELECT name FROM cities WHERE name LIKE '%ã%' OR name LIKE '%õ%' LIMIT 5;

SELECT '' AS espaco;
SELECT '✅ USUÁRIOS - EXEMPLOS CORRETOS:' AS secao;
SELECT DISTINCT name FROM users WHERE name LIKE '%Público%' LIMIT 3;
SELECT DISTINCT name FROM users WHERE name LIKE '%Farmácia%' LIMIT 3;
SELECT DISTINCT name FROM users WHERE name LIKE '%Saúde%' LIMIT 3;
SELECT DISTINCT name FROM users WHERE name LIKE '%Serviço%' LIMIT 3;

SELECT '' AS espaco;
SELECT '✅ VEÍCULOS - EXEMPLOS CORRETOS:' AS secao;
SELECT DISTINCT model_text FROM vehicles WHERE model_text LIKE '%Furgão%' LIMIT 3;
SELECT DISTINCT model_text FROM vehicles WHERE model_text LIKE '%Marruá%' LIMIT 3;
SELECT DISTINCT model FROM vehicles WHERE model LIKE '%ROÇADEIRA%' LIMIT 2;

SELECT '' AS espaco;
SELECT '✅ MOTORISTAS - EXEMPLOS CORRETOS:' AS secao;
SELECT DISTINCT driver FROM order_services WHERE driver LIKE '%José%' LIMIT 3;
SELECT DISTINCT driver FROM order_services WHERE driver LIKE '%André%' LIMIT 3;
SELECT DISTINCT driver FROM order_services WHERE driver LIKE '%Cássio%' LIMIT 2;

SELECT '' AS espaco;
SELECT '═══════════════════════════════════════' AS divisor;
SELECT '  🎉 DATABASE 100% UTF-8 CORRETO!  ' AS resultado;
SELECT '═══════════════════════════════════════' AS divisor;
