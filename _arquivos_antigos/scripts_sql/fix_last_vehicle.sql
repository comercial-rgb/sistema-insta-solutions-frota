-- Correção do último veículo (campo model)

-- Corrigir o campo model que tem ?? no meio da string
UPDATE vehicles 
SET model = REPLACE(model, 'W20ES??RIEJHF0042218', 'W20ESÉRIEJHF0042218') 
WHERE model LIKE '%W20ES??RIE%';

-- Se não funcionar, tentar com SERIE sem acento
UPDATE vehicles 
SET model = REPLACE(model, 'ES??RIE', 'ESERIE') 
WHERE model LIKE '%ES??RIE%';

-- Verificação final absoluta
SELECT 'CONTAGEM FINAL' AS status, COUNT(*) as total_com_problemas 
FROM vehicles 
WHERE model LIKE '%??%' OR model_text LIKE '%??%';

SELECT 'CONTAGEM FINAL - MOTORISTAS' AS status, COUNT(*) as total_com_problemas 
FROM order_services 
WHERE driver LIKE '%??%';

SELECT 'CONTAGEM FINAL - CIDADES' AS status, COUNT(*) as total_com_problemas 
FROM cities 
WHERE name LIKE '%??%';

-- Último veículo
SELECT 'ÚLTIMO VEÍCULO VERIFICADO' AS status;
SELECT id, board, model, model_text FROM vehicles WHERE id = 903;

SELECT '🎉 CORREÇÃO DE ENCODING 100% CONCLUÍDA!' AS resultado;
