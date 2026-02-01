# CORREÇÕES FINAIS - EXECUTE PASSO A PASSO

## 1. Pare processos Ruby
Get-Process | Where-Object {$_.ProcessName -like "*ruby*"} | Stop-Process -Force

## 2. Limpe o cache
Remove-Item -Path "tmp\cache\*" -Recurse -Force
Remove-Item -Path "tmp\pids\*" -Force

## 3. Execute este SQL no MySQL
$query = @'
UPDATE users 
SET name = REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'),
    fantasy_name = REPLACE(REPLACE(fantasy_name, 'óo', 'ão'), 'óa', 'ça')
WHERE name LIKE '%óo%' OR fantasy_name LIKE '%óo%';
'@

echo $query | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -prot123 sistema_insta_solutions_development --default-character-set=utf8mb4

## 4. Inicie o servidor
bundle exec rails server -p 3000

## 5. No navegador:
# - Pressione Ctrl + Shift + Delete
# - Limpe "Cached images and files"
# - Acesse: http://localhost:3000/show_order_services/1
# - Verifique se "Em aberto" aparece UMA vez com (58)
