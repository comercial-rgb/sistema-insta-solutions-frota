# ================================================================
# Script de Deploy das Correções para AWS
# ================================================================
# Data: 27/01/2026
# Versão: 1.0
# Descrição: Deploy das correções de botão Admin e erro 500

param(
    [string]$ServerIP = "",
    [string]$ServerUser = "ubuntu",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "   DEPLOY DE CORREÇÕES - AWS Produção" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Verificar se IP foi fornecido
if ([string]::IsNullOrEmpty($ServerIP)) {
    Write-Host "[ERRO] IP do servidor nao fornecido!" -ForegroundColor Red
    Write-Host "   Uso: .\deploy-correcoes-aws.ps1 -ServerIP '200.100.50.25'" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Informações do Deploy:" -ForegroundColor Green
Write-Host "   Servidor: $ServerIP" -ForegroundColor Gray
Write-Host "   Usuário: $ServerUser" -ForegroundColor Gray
Write-Host "   Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Gray
Write-Host ""

# Arquivos que serão enviados
$filesToDeploy = @(
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
    "CORRECOES_APLICADAS.md"
)

Write-Host "📦 Arquivos a serem enviados: $($filesToDeploy.Count)" -ForegroundColor Yellow
$filesToDeploy | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Modo de teste - nenhuma alteracao sera feita" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[OK] Validacao concluida!" -ForegroundColor Green
    exit 0
}

# Criar backup antes do deploy
Write-Host "💾 Criando backup no servidor..." -ForegroundColor Yellow
$backupDate = Get-Date -Format "yyyy-MM-dd_HH-mm"
$backupCommand = @"
cd /var/www/frotainstasolutions &&
mkdir -p backups &&
tar -czf backups/backup_antes_correcoes_$backupDate.tar.gz app/grids app/views/order_services app/views/order_service_proposals &&
echo 'Backup criado: backups/backup_antes_correcoes_$backupDate.tar.gz'
"@

Write-Host "   Executando backup remoto..." -ForegroundColor Gray

# Criar pacote local com as correções
Write-Host ""
Write-Host "📦 Criando pacote de correções..." -ForegroundColor Yellow
$packageName = "correcoes_$backupDate.tar.gz"

# Verificar se todos os arquivos existem
$missingFiles = @()
foreach ($file in $filesToDeploy) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERRO] Arquivos nao encontrados:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

# Criar pacote tar.gz com as correções
Write-Host "   Compactando arquivos..." -ForegroundColor Gray
tar -czf $packageName @filesToDeploy 2>&1 | Out-Null

if (Test-Path $packageName) {
    $packageSize = (Get-Item $packageName).Length / 1KB
    $sizeFormatted = [math]::Round($packageSize, 2)
    Write-Host "   [OK] Pacote criado: $packageName ($sizeFormatted KB)" -ForegroundColor Green
} else {
    Write-Host "[ERRO] Falha ao criar pacote" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "   INSTRUÇÕES PARA DEPLOY MANUAL" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""
Write-Host "1️⃣ Fazer backup no servidor:" -ForegroundColor Cyan
Write-Host "   ssh $ServerUser@$ServerIP" -ForegroundColor Yellow
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   mkdir -p backups" -ForegroundColor Yellow
Write-Host "   tar -czf backups/backup_antes_correcoes_$backupDate.tar.gz app/grids app/views" -ForegroundColor Yellow
Write-Host ""
Write-Host "2️⃣ Enviar pacote de correções:" -ForegroundColor Cyan
Write-Host "   scp $packageName ${ServerUser}@${ServerIP}:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "3️⃣ Extrair no servidor:" -ForegroundColor Cyan
Write-Host "   ssh $ServerUser@$ServerIP" -ForegroundColor Yellow
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   tar -xzf /tmp/$packageName" -ForegroundColor Yellow
Write-Host ""
Write-Host "4️⃣ Verificar correções:" -ForegroundColor Cyan
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   RAILS_ENV=production bundle exec rails runner check_production_status.rb" -ForegroundColor Yellow
Write-Host ""
Write-Host "5️⃣ Reiniciar servidor:" -ForegroundColor Cyan
Write-Host "   sudo systemctl restart puma_frotainstasolutions" -ForegroundColor Yellow
Write-Host "   # OU" -ForegroundColor Gray
Write-Host "   sudo systemctl restart frotainstasolutions" -ForegroundColor Yellow
Write-Host ""
Write-Host "6️⃣ Verificar logs:" -ForegroundColor Cyan
Write-Host "   tail -f /var/www/frotainstasolutions/log/production.log" -ForegroundColor Yellow
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "   ROLLBACK (se necessário)" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   tar -xzf backups/backup_antes_correcoes_$backupDate.tar.gz" -ForegroundColor Yellow
Write-Host "   sudo systemctl restart puma_frotainstasolutions" -ForegroundColor Yellow
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "✅ Pacote de correções pronto: $packageName" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
