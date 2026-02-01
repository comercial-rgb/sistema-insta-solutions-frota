-- Corrigir TODOS os encodings

-- 1. Users (managers, additional, providers)
UPDATE users 
SET 
  name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  fantasy_name = REPLACE(REPLACE(REPLACE(fantasy_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  social_name = REPLACE(REPLACE(REPLACE(social_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE 
  name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%'
  OR fantasy_name LIKE '%óo%' OR fantasy_name LIKE '%óa%' OR fantasy_name LIKE '%çãoo%'
  OR social_name LIKE '%óo%' OR social_name LIKE '%óa%' OR social_name LIKE '%çãoo%';

-- 2. Cities (todas)
UPDATE cities 
SET name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%';

-- 3. Banks
UPDATE banks 
SET name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%';

SELECT 'Correções de encoding aplicadas!' as resultado;
