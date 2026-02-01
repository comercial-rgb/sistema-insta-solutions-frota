-- Verificar registros específicos mencionados pelo usuário

SELECT 'Cidades com Ibirauçu' AS tipo;
SELECT id, name FROM cities WHERE name LIKE '%Ibirau%' LIMIT 10;

SELECT 'Usuários/Clientes com Público' AS tipo;
SELECT id, name, fantasy_name FROM users WHERE name LIKE '%úblico%' OR fantasy_name LIKE '%úblico%' LIMIT 10;

SELECT 'Usuários/Clientes com Farmácia' AS tipo;
SELECT id, name, fantasy_name FROM users WHERE name LIKE '%Farmá%' OR fantasy_name LIKE '%Farmá%' LIMIT 10;

SELECT 'Usuários/Clientes com Serviço' AS tipo;
SELECT id, name, fantasy_name FROM users WHERE name LIKE '%Servi%' LIMIT 10;

SELECT 'Usuários/Clientes com Saúde' AS tipo;
SELECT id, name, fantasy_name FROM users WHERE name LIKE '%Saú%' OR fantasy_name LIKE '%Saú%' LIMIT 10;

SELECT 'Usuários/Clientes com Aperfeiçoamento' AS tipo;
SELECT id, name, fantasy_name FROM users WHERE name LIKE '%Aperfei%' OR fantasy_name LIKE '%Aperfei%' LIMIT 10;

SELECT 'Cidades com água' AS tipo;
SELECT id, name FROM cities WHERE name LIKE '%água%' OR name LIKE '%Água%' LIMIT 10;

SELECT 'Cidades com ção' AS tipo;
SELECT id, name FROM cities WHERE name LIKE '%ção%' LIMIT 10;
