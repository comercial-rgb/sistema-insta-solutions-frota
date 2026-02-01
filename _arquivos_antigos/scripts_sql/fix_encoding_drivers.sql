-- Correções adicionais de encoding em nomes de motoristas

UPDATE order_services SET driver = REPLACE(driver, 'Lu??s', 'Luís') WHERE driver LIKE '%Lu??s%';
UPDATE order_services SET driver = REPLACE(driver, 'Val??rio', 'Valério') WHERE driver LIKE '%Val??rio%';
UPDATE order_services SET driver = REPLACE(driver, 'H??linton', 'Hélinton') WHERE driver LIKE '%H??linton%';

SELECT 'Correções adicionais de motoristas aplicadas' AS resultado;
