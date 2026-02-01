#!/usr/bin/env pwsh
# ================================================================
# Script de Deploy - Correções Sistema Insta Solutions
# Data: 29/01/2026
# ================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOY - Correções Sistema Insta" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$SERVER = "ec2-user@3.226.131.200"
$REMOTE_PATH = "/var/www/frotainstasolutions/production"
$LOCAL_PATH = "c:\Users\Usuário\Desktop\sistema-insta-solutions"

# Arquivos a enviar
$files = @(
    # Views
    "app/views/order_services/show.html.erb",
    "app/views/order_services/renders/_items_panel.html.erb",
    "app/views/order_services/forms/_form_data.html.erb",
    "app/views/provider_dashboard/index.html.erb",
    "app/views/service_groups/_form.html.erb",
    
    # Models
    "app/models/service_group.rb",
    "app/models/service_group_client.rb",
    
    # Controllers
    "app/controllers/service_groups_controller.rb",
    
    # Migration
    "db/migrate/20260129182100_add_client_filter_to_service_groups.rb"
)

Write-Host "Enviando arquivos para produção..." -ForegroundColor Yellow

foreach ($file in $files) {
    $fullPath = Join-Path $LOCAL_PATH $file
    
    if (Test-Path $fullPath) {
        $remotePath = "$REMOTE_PATH/$($file -replace '\\', '/')"
        $remoteDir = Split-Path $remotePath -Parent
        
        Write-Host "  -> $file" -ForegroundColor Gray
        
        # Criar diretório remoto se não existir
        ssh $SERVER "mkdir -p $remoteDir"
        
        # Enviar arquivo
        scp $fullPath "$SERVER`:$remotePath"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "     ✓ Enviado" -ForegroundColor Green
        } else {
            Write-Host "     ✗ ERRO ao enviar!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ✗ Arquivo não encontrado: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nExecutando comandos remotos..." -ForegroundColor Yellow

# Executar migrations e restart
$commands = @"
cd $REMOTE_PATH && \
echo '=== Executando migrations ===' && \
RAILS_ENV=production bundle exec rake db:migrate && \
echo '=== Reiniciando servidor ===' && \
sudo systemctl restart frotainstasolutions && \
sleep 3 && \
sudo systemctl status frotainstasolutions --no-pager -l
"@

Write-Host "`nComandos a executar:" -ForegroundColor Cyan
Write-Host $commands -ForegroundColor Gray

ssh $SERVER $commands

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✓ DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    Write-Host "Alterações implementadas:" -ForegroundColor Yellow
    Write-Host "  1. ✓ Painel de itens da OS (Cotações, Requisição, Diagnóstico)" -ForegroundColor White
    Write-Host "  2. ✓ Dashboard Provider - centro de custo e subunidade" -ForegroundColor White
    Write-Host "  3. ✓ Filtro Rejeições - fornecedor rejeitado (já existia)" -ForegroundColor White
    Write-Host "  4. ✓ Service Groups - filtro por cliente" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "✗ ERRO NO DEPLOY!" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Red
    exit 1
}
