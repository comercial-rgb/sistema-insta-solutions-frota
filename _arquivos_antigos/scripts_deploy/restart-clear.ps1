# Script para reiniciar servidor com limpeza completa

Write-Host "Parando processos Ruby..." -ForegroundColor Yellow
Get-Process ruby -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

Write-Host "Limpando cache..." -ForegroundColor Yellow
Remove-Item -Path "tmp\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "tmp\pids\*" -Force -ErrorAction SilentlyContinue

Write-Host "`nCache limpo! Agora execute: .\quick-start.ps1" -ForegroundColor Green
Write-Host "E no navegador, pressione Ctrl+Shift+R para limpar cache" -ForegroundColor Cyan
