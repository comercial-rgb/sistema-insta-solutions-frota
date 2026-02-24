#!/usr/bin/env pwsh
# ================================================================
# Script de Deploy - Catálogo de Peças + Padronização + Encoding
# Data: 24/02/2026
# ================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOY - Catálogo + Padronização" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$SSH_KEY = "$env:USERPROFILE\.ssh\frotainstasolutions-keypair.pem"
$SERVER = "ubuntu@3.226.131.200"
$REMOTE_PATH = "/var/www/frotainstasolutions/production"
$LOCAL_PATH = "c:\Users\Usuário\Desktop\sistema-insta-solutions"

# ================================================================
# ARQUIVOS A ENVIAR
# ================================================================
$files = @(
    # === COMMIT 1: Catálogo de Peças ===
    # Models
    "app/models/catalogo_peca.rb",
    "app/models/catalogo_pdf_import.rb",
    
    # Controller
    "app/controllers/catalogo_pecas_controller.rb",
    
    # Service
    "app/services/utils/catalogo/search_service.rb",
    
    # Migration
    "db/migrate/20260224120000_create_catalogo_pecas.rb",
    
    # Rake Task
    "lib/tasks/catalogo_pecas.rake",
    
    # Routes
    "config/routes.rb",
    
    # === COMMIT 2: Padronização + Encoding ===
    # Concern
    "app/models/concerns/padroniza_nome.rb",
    
    # Models (com include PadronizaNome)
    "app/models/service.rb",
    "app/models/provider_service_temp.rb",
    "app/models/order_service_proposal_item.rb",
    
    # Rake Task
    "lib/tasks/padronizar_nomes.rake",
    
    # === COMMIT 3: Referência Catálogo no Formulário ===
    # Migration
    "db/migrate/20260224150000_add_referencia_catalogo.rb",
    
    # Controller
    "app/controllers/order_service_proposals_controller.rb",
    
    # View
    "app/views/order_service_proposals/forms/_provider_service_temp_fields.html.erb",
    
    # Schema
    "db/schema.rb"
)

# ================================================================
# ETAPA 1: Enviar arquivos
# ================================================================
Write-Host "ETAPA 1/4 - Enviando $($files.Count) arquivos para produção..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($file in $files) {
    $fullPath = Join-Path $LOCAL_PATH $file
    
    if (Test-Path $fullPath) {
        $remotePath = "$REMOTE_PATH/$($file -replace '\\', '/')"
        $remoteDir = Split-Path $remotePath -Parent
        
        Write-Host "  -> $file" -ForegroundColor Gray -NoNewline
        
        # Criar diretório remoto se não existir
        ssh -o ConnectTimeout=10 -i $SSH_KEY $SERVER "mkdir -p $remoteDir" 2>$null
        
        # Enviar arquivo
        scp -o ConnectTimeout=10 -i $SSH_KEY $fullPath "$SERVER`:$remotePath" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " ✗ ERRO!" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  ✗ Não encontrado: $file" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "  Enviados: $successCount / $($files.Count)" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Yellow" })

if ($errorCount -gt 0) {
    Write-Host "  ERROS: $errorCount" -ForegroundColor Red
    $continue = Read-Host "Continuar mesmo com erros? (s/N)"
    if ($continue -ne "s" -and $continue -ne "S") {
        Write-Host "Deploy cancelado." -ForegroundColor Red
        exit 1
    }
}

# ================================================================
# ETAPA 2: Criar diretório do service (caso não exista)
# ================================================================
Write-Host "`nETAPA 2/4 - Garantindo estrutura de diretórios..." -ForegroundColor Yellow

ssh -i $SSH_KEY $SERVER "mkdir -p $REMOTE_PATH/app/services/utils/catalogo"
Write-Host "  ✓ Diretórios verificados" -ForegroundColor Green

# ================================================================
# ETAPA 3: Executar migrations
# ================================================================
Write-Host "`nETAPA 3/4 - Executando migrations..." -ForegroundColor Yellow

$migrationCmd = @"
cd $REMOTE_PATH && \
source ~/.bashrc && \
echo '--- Migrations pendentes ---' && \
RAILS_ENV=production bundle exec rake db:migrate:status 2>/dev/null | tail -5 && \
echo '' && \
echo '--- Executando migrations ---' && \
RAILS_ENV=production bundle exec rake db:migrate && \
echo '--- Migrations concluídas ---'
"@

ssh -i $SSH_KEY $SERVER $migrationCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Migrations executadas com sucesso" -ForegroundColor Green
} else {
    Write-Host "  ✗ Erro nas migrations!" -ForegroundColor Red
    $continue = Read-Host "Continuar com o restart? (s/N)"
    if ($continue -ne "s" -and $continue -ne "S") {
        Write-Host "Deploy cancelado." -ForegroundColor Red
        exit 1
    }
}

# ================================================================
# ETAPA 4: Precompile assets + Restart
# ================================================================
Write-Host "`nETAPA 4/4 - Precompilando assets e reiniciando servidor..." -ForegroundColor Yellow

$restartCmd = @"
cd $REMOTE_PATH && \
source ~/.bashrc && \
echo '--- Precompilando assets ---' && \
RAILS_ENV=production bundle exec rake assets:precompile && \
echo '--- Limpando cache ---' && \
RAILS_ENV=production bundle exec rake tmp:cache:clear && \
echo '--- Reiniciando servidor ---' && \
sudo systemctl restart frotainstasolutions && \
sleep 3 && \
echo '--- Status do servidor ---' && \
sudo systemctl status frotainstasolutions --no-pager -l
"@

ssh -i $SSH_KEY $SERVER $restartCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "O que foi atualizado:" -ForegroundColor Cyan
    Write-Host "  1. Catálogo de Peças (172.737 registros - importação via rake)" -ForegroundColor White
    Write-Host "  2. Padronização de nomes (Title Case + 100 termos auto)" -ForegroundColor White
    Write-Host "  3. Correção de encoding (200+ padrões)" -ForegroundColor White
    Write-Host "  4. Campo 'Ref. Catálogo' no formulário de propostas" -ForegroundColor White
    Write-Host ""
    Write-Host "PRÓXIMOS PASSOS (manuais no servidor):" -ForegroundColor Yellow
    Write-Host "  1. Importar catálogos: RAILS_ENV=production bundle exec rake catalogo:importar_todos" -ForegroundColor Gray
    Write-Host "     (Requer PDFs copiados para catalogo_pdf/ no servidor)" -ForegroundColor DarkGray
    Write-Host "  2. Padronizar nomes existentes: RAILS_ENV=production bundle exec rake padronizar:aplicar" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  DEPLOY COM PROBLEMAS!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Verifique o status do servidor manualmente:" -ForegroundColor Yellow
    Write-Host "  ssh -i $SSH_KEY $SERVER 'sudo systemctl status frotainstasolutions'" -ForegroundColor Gray
}
