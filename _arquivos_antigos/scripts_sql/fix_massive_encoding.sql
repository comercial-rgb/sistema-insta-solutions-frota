-- Correção massiva de encoding em TODO o banco de dados
-- Baseado nos padrões identificados pelo usuário

-- ======================
-- CIDADES - PADRÕES COMUNS
-- ======================

-- â → ã (exemplo: Brasilâia → Brasiliâ)
UPDATE cities SET name = REPLACE(name, 'Acrelândia', 'Acrelândia') WHERE name LIKE '%Acrelândia%';
UPDATE cities SET name = REPLACE(name, 'Brasilâia', 'Brasiléia') WHERE name LIKE '%Brasilâia%';
UPDATE cities SET name = REPLACE(name, 'Epitaciolândia', 'Epitaciolândia') WHERE name LIKE '%Epitaciolândia%';
UPDATE cities SET name = REPLACE(name, 'Feijâ', 'Feijó') WHERE name LIKE '%Feijâ%';
UPDATE cities SET name = REPLACE(name, 'Jordâo', 'Jordão') WHERE name LIKE '%Jordâo%';
UPDATE cities SET name = REPLACE(name, 'Mâncio', 'Mâncio') WHERE name LIKE '%Mâncio%';
UPDATE cities SET name = REPLACE(name, 'Plãcido', 'Plácido') WHERE name LIKE '%Plãcido%';
UPDATE cities SET name = REPLACE(name, 'Tarauacã', 'Tarauacá') WHERE name LIKE '%Tarauacã%';
UPDATE cities SET name = REPLACE(name, 'ãgua', 'Água') WHERE name LIKE '%ãgua%';
UPDATE cities SET name = REPLACE(name, 'Belãm', 'Belém') WHERE name LIKE '%Belãm%';
UPDATE cities SET name = REPLACE(name, 'Antônio', 'Antônio') WHERE name LIKE '%Antônio%';
UPDATE cities SET name = REPLACE(name, 'Chã ', 'Chã ') WHERE name LIKE '%Chã %';
UPDATE cities SET name = REPLACE(name, 'Coitã', 'Coité') WHERE name LIKE '%Coitã%';
UPDATE cities SET name = REPLACE(name, 'Nãia', 'Noia') WHERE name LIKE '%Nãia%';
UPDATE cities SET name = REPLACE(name, 'Colãnia', 'Colônia') WHERE name LIKE '%Colãnia%';
UPDATE cities SET name = REPLACE(name, 'Craãbas', 'Craíbas') WHERE name LIKE '%Craãbas%';

-- Ibirauçu (caso específico mencionado pelo usuário)
UPDATE cities SET name = REPLACE(name, 'Ibiraul', 'Ibirauçu') WHERE name LIKE '%Ibiraul%';
UPDATE cities SET name = REPLACE(name, 'Ibirauç', 'Ibirauçu') WHERE name LIKE '%Ibirauç%' AND name NOT LIKE '%Ibirauçu%';

-- ======================
-- USUÁRIOS - NOMES PÚBLICOS
-- ======================

-- Póblico → Público
UPDATE users SET name = REPLACE(name, 'Póblico', 'Público') WHERE name LIKE '%Póblico%';
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'Póblico', 'Público') WHERE fantasy_name LIKE '%Póblico%';

-- Farmócia → Farmácia  
UPDATE users SET name = REPLACE(name, 'Farmócia', 'Farmácia') WHERE name LIKE '%Farmócia%';
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'Farmócia', 'Farmácia') WHERE fantasy_name LIKE '%Farmócia%';

-- Servião → Serviço
UPDATE users SET name = REPLACE(name, 'Servião', 'Serviço') WHERE name LIKE '%Servião%';
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'Servião', 'Serviço') WHERE fantasy_name LIKE '%Servião%';

-- Aperfeiãoamento → Aperfeiçoamento
UPDATE users SET name = REPLACE(name, 'Aperfeiãoamento', 'Aperfeiçoamento') WHERE name LIKE '%Aperfeiãoamento%';
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'Aperfeiãoamento', 'Aperfeiçoamento') WHERE fantasy_name LIKE '%Aperfeiãoamento%';

-- Saóde → Saúde
UPDATE users SET name = REPLACE(name, 'Saóde', 'Saúde') WHERE name LIKE '%Saóde%';
UPDATE users SET fantasy_name = REPLACE(fantasy_name, 'Saóde', 'Saúde') WHERE fantasy_name LIKE '%Saóde%';

-- ======================
-- CENTROS DE CUSTO
-- ======================

UPDATE cost_centers SET name = REPLACE(name, 'Póblico', 'Público') WHERE name LIKE '%Póblico%';
UPDATE cost_centers SET name = REPLACE(name, 'Farmócia', 'Farmácia') WHERE name LIKE '%Farmócia%';
UPDATE cost_centers SET name = REPLACE(name, 'Servião', 'Serviço') WHERE name LIKE '%Servião%';
UPDATE cost_centers SET name = REPLACE(name, 'Saóde', 'Saúde') WHERE name LIKE '%Saóde%';
UPDATE cost_centers SET name = REPLACE(name, 'Aperfeiãoamento', 'Aperfeiçoamento') WHERE name LIKE '%Aperfeiãoamento%';

-- ======================
-- SUBUNIDADES
-- ======================

UPDATE sub_units SET name = REPLACE(name, 'Póblico', 'Público') WHERE name LIKE '%Póblico%';
UPDATE sub_units SET name = REPLACE(name, 'Farmócia', 'Farmácia') WHERE name LIKE '%Farmócia%';
UPDATE sub_units SET name = REPLACE(name, 'Servião', 'Serviço') WHERE name LIKE '%Servião%';
UPDATE sub_units SET name = REPLACE(name, 'Saóde', 'Saúde') WHERE name LIKE '%Saóde%';

-- ======================
-- VERIFICAÇÃO
-- ======================

SELECT '=== VERIFICAÇÃO PÓS-CORREÇÃO ===' AS status;

SELECT 'Cidades com problemas restantes' AS tipo, COUNT(*) as total
FROM cities WHERE name LIKE '%ã%' OR name LIKE '%ó%' OR name LIKE '%aul%';

SELECT 'Usuários com problemas restantes' AS tipo, COUNT(*) as total
FROM users WHERE name LIKE '%ó%' OR name LIKE '%ã%' OR fantasy_name LIKE '%ó%' OR fantasy_name LIKE '%ã%';

SELECT 'Centros de custo com problemas restantes' AS tipo, COUNT(*) as total
FROM cost_centers WHERE name LIKE '%ó%' OR name LIKE '%ã%';

SELECT 'Subunidades com problemas restantes' AS tipo, COUNT(*) as total
FROM sub_units WHERE name LIKE '%ó%' OR name LIKE '%ã%';

-- Exemplos corrigidos
SELECT 'Exemplos de cidades corrigidas' AS tipo;
SELECT name FROM cities WHERE name LIKE '%Água%' OR name LIKE '%Ibirauçu%' OR name LIKE '%Belém%' LIMIT 10;

SELECT '✅ CORREÇÃO MASSIVA DE ENCODING CONCLUÍDA!' AS resultado;
