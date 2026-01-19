# ================================================================
# STOP SERVER - Sistema Insta Solutions
# ================================================================
# Para todos os processos Ruby/Rails em execução

Write-Host "`n[!] Parando Sistema Insta Solutions..." -ForegroundColor Yellow
Write-Host ""

$rubyProcesses = Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}

if ($rubyProcesses) {
    Write-Host ">> Encontrados $($rubyProcesses.Count) processo(s) Ruby:" -ForegroundColor Cyan
    $rubyProcesses | ForEach-Object {
        Write-Host "   - PID: $($_.Id) | Iniciado: $($_.StartTime)" -ForegroundColor Gray
    }
    
    Write-Host "`n>> Parando processos..." -ForegroundColor Yellow
    $rubyProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    # Verificar se parou
    $remaining = Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}
    if ($remaining) {
        Write-Host "[!] Alguns processos ainda estão rodando. Tentando força total..." -ForegroundColor Yellow
        $remaining | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    
    Write-Host "[OK] Todos os processos foram parados!" -ForegroundColor Green
} else {
    Write-Host "[i] Nenhum processo Ruby em execução" -ForegroundColor Gray
}

Write-Host ""
