# ================================================================
# CORREÇÃO DEFINITIVA - Sistema Insta Solutions
# ================================================================
# Este script:
# 1. Para todos os processos Ruby
# 2. Limpa cache completamente
# 3. Aplica correções SQL de encoding
# 4. Reinicia o servidor
# ================================================================

$ErrorActionPreference = "Continue"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "CORREÇÃO DEFINITIVA - Sistema Insta Solutions" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# ================================================================
# 1. PARAR PROCESSOS RUBY
# ================================================================
Write-Host "[1/5] Parando processos Ruby..." -ForegroundColor Yellow
$rubyProcesses = Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}
if ($rubyProcesses) {
    $rubyProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "  ✓ $($rubyProcesses.Count) processo(s) parado(s)" -ForegroundColor Green
} else {
    Write-Host "  ✓ Nenhum processo Ruby rodando" -ForegroundColor Green
}

# ================================================================
# 2. LIMPAR CACHE
# ================================================================
Write-Host "`n[2/5] Limpando cache Rails..." -ForegroundColor Yellow
Remove-Item -Path "tmp\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "tmp\pids\*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "tmp\sessions\*" -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Cache limpo" -ForegroundColor Green

# ================================================================
# 3. VERIFICAR STATUS NO BANCO
# ================================================================
Write-Host "`n[3/5] Verificando status no banco de dados..." -ForegroundColor Yellow
$statusQuery = "SELECT id, name FROM order_service_statuses WHERE id IN (1, 9) ORDER BY id;"

echo $statusQuery | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -prot123 sistema_insta_solutions_development --default-character-set=utf8mb4 -t 2>$null

# ================================================================
# 4. APLICAR CORREÇÕES DE ENCODING
# ================================================================
Write-Host "`n[4/5] Aplicando correções de encoding (Users e Cities)..." -ForegroundColor Yellow

# Criar arquivo SQL temporário
$sqlFile = "tmp\fix_encoding_temp.sql"
@"
UPDATE users 
SET 
  name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  fantasy_name = REPLACE(REPLACE(REPLACE(fantasy_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção'),
  social_name = REPLACE(REPLACE(REPLACE(social_name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE 
  name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%'
  OR fantasy_name LIKE '%óo%' OR fantasy_name LIKE '%óa%' OR fantasy_name LIKE '%çãoo%'
  OR social_name LIKE '%óo%' OR social_name LIKE '%óa%' OR social_name LIKE '%çãoo%';

UPDATE cities 
SET name = REPLACE(REPLACE(REPLACE(name, 'óo', 'ão'), 'óa', 'ça'), 'çãoo', 'ção')
WHERE name LIKE '%óo%' OR name LIKE '%óa%' OR name LIKE '%çãoo%'
LIMIT 1000;
"@ | Out-File -FilePath $sqlFile -Encoding utf8

Get-Content $sqlFile | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -prot123 sistema_insta_solutions_development --default-character-set=utf8mb4 2>$null
Remove-Item $sqlFile -Force

Write-Host "  ✓ Encoding corrigido (Users + primeiras 1000 cities)" -ForegroundColor Green

# ================================================================
# 5. INICIAR SERVIDOR
# ================================================================
Write-Host "`n[5/5] Iniciando servidor Rails..." -ForegroundColor Yellow
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "SERVIDOR RAILS - http://localhost:3000" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "`nPressione Ctrl+C para parar o servidor`n" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Gray

# Iniciar servidor
bundle exec rails server -p 3000
