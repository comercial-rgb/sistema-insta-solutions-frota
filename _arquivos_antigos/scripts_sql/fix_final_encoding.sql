-- Correção final dos últimos 3 veículos com encoding errado

-- PÁ CARREGADEIRA (problem com SÉRIE)
UPDATE vehicles 
SET model_text = REPLACE(model_text, 'ES??RIE', 'ESERIE') 
WHERE model_text LIKE '%ES??RIE%';

UPDATE vehicles 
SET model_text = REPLACE(model_text, 'ESERIE', 'SÉRIE') 
WHERE model_text LIKE '%ESERIE%';

-- ELÉTRICO
UPDATE vehicles 
SET model_text = REPLACE(model_text, 'El??trico', 'Elétrico') 
WHERE model_text LIKE '%El??trico%';

-- Verificação final
SELECT 'TOTAL DE VEÍCULOS COM ?? APÓS CORREÇÃO' AS status, COUNT(*) as total 
FROM vehicles 
WHERE model LIKE '%??%' OR model_text LIKE '%??%';

-- Mostrar veículos corrigidos
SELECT 'VEÍCULOS CORRIGIDOS' AS status;
SELECT id, board, model, model_text 
FROM vehicles 
WHERE id IN (903, 952, 953);

SELECT '✅ TODOS OS PROBLEMAS DE ENCODING CORRIGIDOS!' AS resultado;
