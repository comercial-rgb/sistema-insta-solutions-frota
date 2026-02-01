# ================================================================
# Script Simples de Empacotamento para Deploy AWS
# ================================================================

$ErrorActionPreference = "Stop"

Write-Host "================================================================================
" -ForegroundColor Cyan
Write-Host "   CRIANDO PACOTE DE CORRECOES PARA AWS" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$packageName = "correcoes_os_fix_$timestamp.tar.gz"

Write-Host "Criando pacote: $packageName" -ForegroundColor Yellow
Write-Host ""

# Lista de arquivos
$files = @(
    "app/grids/order_service_proposals_grid.rb",
    "app/grids/order_services_grid.rb",
    "app/views/order_service_proposals/print_order_service_proposals_by_order_service.html.erb",
    "app/views/order_service_proposals/show_order_service_proposal.html.erb",
    "app/views/order_service_proposals/show_order_service_proposals_by_order_service.html.erb",
    "app/views/order_services/_form.html.erb",
    "app/views/order_services/_show_order_service_status.html.erb",
    "app/views/order_services/edit.html.erb",
    "app/views/order_services/show.html.erb",
    "app/views/order_services/show_historic.html.erb",
    "check_production_status.rb",
    "validate_fixes.rb",
    "CORRECOES_APLICADAS.md",
    "DEPLOY_CORRECOES_RAPIDO.md"
)

Write-Host "Arquivos incluidos:" -ForegroundColor Green
$files | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

Write-Host "Compactando..." -ForegroundColor Yellow
tar -czf $packageName @files

if (Test-Path $packageName) {
    $size = (Get-Item $packageName).Length / 1024
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "   PACOTE CRIADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Arquivo: $packageName" -ForegroundColor Cyan
    Write-Host "Tamanho: $([math]::Round($size, 2)) KB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "   INSTRUCOES DE DEPLOY" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Conectar ao servidor AWS:" -ForegroundColor Cyan
    Write-Host "   ssh ubuntu@SEU_IP_AWS" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Fazer backup no servidor:" -ForegroundColor Cyan
    Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor White
    Write-Host "   mkdir -p backups" -ForegroundColor White
    Write-Host "   tar -czf backups/backup_$timestamp.tar.gz app/grids app/views" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Enviar pacote (do seu computador):" -ForegroundColor Cyan
    Write-Host "   scp $packageName ubuntu@SEU_IP_AWS:/tmp/" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Extrair no servidor:" -ForegroundColor Cyan
    Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor White
    Write-Host "   tar -xzf /tmp/$packageName" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Validar:" -ForegroundColor Cyan
    Write-Host "   RAILS_ENV=production bundle exec rails runner check_production_status.rb" -ForegroundColor White
    Write-Host ""
    Write-Host "6. Reiniciar:" -ForegroundColor Cyan
    Write-Host "   sudo systemctl restart puma_frotainstasolutions" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Leia DEPLOY_CORRECOES_RAPIDO.md para instrucoes detalhadas!" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "ERRO: Falha ao criar pacote!" -ForegroundColor Red
    exit 1
}
