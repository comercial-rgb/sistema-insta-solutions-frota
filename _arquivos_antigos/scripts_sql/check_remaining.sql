-- Buscar veículos restantes com ??
SELECT id, board, model, model_text FROM vehicles WHERE model LIKE '%??%' OR model_text LIKE '%??%';
