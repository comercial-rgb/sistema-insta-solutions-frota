-- Script para corrigir encoding de textos corrompidos
-- Executar em produção para corrigir caracteres especiais

-- Corrigir "LOTA????O" para "LOTAÇÃO"
UPDATE vehicles SET model_text = REPLACE(model_text, 'LOTA????O', 'LOTAÇÃO') WHERE model_text LIKE '%LOTA????O%';
UPDATE vehicles SET model = REPLACE(model, 'LOTA????O', 'LOTAÇÃO') WHERE model LIKE '%LOTA????O%';

-- Corrigir "Esperanêa" para "Esperança" (deve ser Ç não Ê)
UPDATE cities SET name = REPLACE(name, 'Esperanêa', 'Esperança') WHERE name LIKE '%Esperanêa%';

-- Corrigir "Cuiabá" (já está correto se for BA, mas verificar se não é BÁ)
-- Manter como está, pois Cuiabá é a forma correta

-- Corrigir "Boqueirêo" para "Boqueirão"
UPDATE cities SET name = REPLACE(name, 'Boqueirêo', 'Boqueirão') WHERE name LIKE '%Boqueirêo%';
UPDATE sub_units SET name = REPLACE(name, 'Boqueirêo', 'Boqueirão') WHERE name LIKE '%Boqueirêo%';
UPDATE cost_centers SET name = REPLACE(name, 'Boqueirêo', 'Boqueirão') WHERE name LIKE '%Boqueirêo%';

-- Corrigir "Antênio" para "Antônio"
UPDATE order_services SET driver = REPLACE(driver, 'Antênio', 'Antônio') WHERE driver LIKE '%Antênio%';
UPDATE users SET name = REPLACE(name, 'Antênio', 'Antônio') WHERE name LIKE '%Antênio%';

-- Corrigir "Osêrio" para "Osório"
UPDATE cities SET name = REPLACE(name, 'Osêrio', 'Osório') WHERE name LIKE '%Osêrio%';
UPDATE sub_units SET name = REPLACE(name, 'Osêrio', 'Osório') WHERE name LIKE '%Osêrio%';

-- Corrigir outros padrões comuns de encoding errado
-- Ç incorreto (êa, êo)
UPDATE vehicles SET model_text = REPLACE(REPLACE(model_text, 'Çêa', 'ção'), 'Çêo', 'ção') WHERE model_text LIKE '%Çê%';
UPDATE vehicles SET model = REPLACE(REPLACE(model, 'Çêa', 'ção'), 'Çêo', 'ção') WHERE model LIKE '%Çê%';

-- Ã incorreto (êa, ãê)
UPDATE order_services SET details = REPLACE(REPLACE(details, 'nêo', 'não'), 'Çêo', 'ção') WHERE details LIKE '%êo%';

-- Exibir exemplos de dados que ainda podem ter problemas
SELECT 'Veículos com possíveis erros:' AS info;
SELECT id, model, model_text FROM vehicles WHERE 
  model LIKE '%?%' OR model_text LIKE '%?%' 
  OR model LIKE '%ê%' OR model_text LIKE '%ê%'
  OR model LIKE '%Ç%' OR model_text LIKE '%Ç%'
LIMIT 10;

SELECT 'Cidades com possíveis erros:' AS info;
SELECT id, name FROM cities WHERE 
  name LIKE '%?%' 
  OR name LIKE '%ê%' 
LIMIT 10;

SELECT 'Motoristas com possíveis erros:' AS info;
SELECT DISTINCT driver FROM order_services WHERE 
  driver LIKE '%?%' 
  OR driver LIKE '%ê%' 
LIMIT 10;
