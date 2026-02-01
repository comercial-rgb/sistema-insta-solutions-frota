-- Script para encontrar todos os problemas de encoding

-- Veículos com ??
SELECT 'VEICULOS COM ??' AS tipo, id, model, model_text 
FROM vehicles 
WHERE model LIKE '%??%' OR model_text LIKE '%??%'
LIMIT 20;

-- Cidades com ??
SELECT 'CIDADES COM ??' AS tipo, id, name 
FROM cities 
WHERE name LIKE '%??%'
LIMIT 20;

-- Order Services - motoristas com ??
SELECT 'MOTORISTAS COM ??' AS tipo, id, driver 
FROM order_services 
WHERE driver LIKE '%??%'
LIMIT 20;

-- Subunidades com ??
SELECT 'SUBUNIDADES COM ??' AS tipo, id, name 
FROM sub_units 
WHERE name LIKE '%??%'
LIMIT 20;

-- Centros de custo com ??
SELECT 'CENTROS CUSTO COM ??' AS tipo, id, name 
FROM cost_centers 
WHERE name LIKE '%??%'
LIMIT 20;

-- Cidade Esperançã
SELECT 'CIDADE ESPERANCA ERRADA' AS tipo, id, name 
FROM cities 
WHERE name LIKE '%Esperanç%';
