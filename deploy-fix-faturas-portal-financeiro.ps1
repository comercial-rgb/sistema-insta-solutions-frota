#!/usr/bin/env pwsh
# ================================================================
# Script de Deploy - Fix OSs não aparecem no Portal Financeiro (Faturas)
# Data: 02/03/2026
# Problema: OSs autorizadas de "Conceição do Castelo" (e potencialmente
#           outros clientes) não apareciam na tela de Faturas.
# Causa: Scope approved_in_current_month usava SQL raw com LIKE frágil
#        e IDs hardcoded que não capturavam todas as autorizações.
# ================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOY - Fix Portal Financeiro / Faturas" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$SSH_KEY = "$env:USERPROFILE\.ssh\frotainstasolutions-keypair.pem"
$SERVER = "ubuntu@3.226.131.200"
$REMOTE_PATH = "/var/www/frotainstasolutions/production"
$LOCAL_PATH = $PSScriptRoot

# ================================================================
# ARQUIVOS A ENVIAR
# ================================================================
$files = @(
    "app/models/order_service_status.rb",
    "app/models/order_service.rb",
    "app/services/webhook_finance_service.rb"
)

# ================================================================
# ETAPA 1: Enviar arquivos
# ================================================================
Write-Host "ETAPA 1/2 - Enviando $($files.Count) arquivos para producao..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($file in $files) {
    $fullPath = Join-Path $LOCAL_PATH ($file -replace '/', '\')

    if (Test-Path $fullPath) {
        $remotePath = "$REMOTE_PATH/$($file -replace '\\', '/')"
        $remoteDir = Split-Path $remotePath -Parent

        Write-Host "  -> $file" -ForegroundColor Gray -NoNewline

        ssh -o ConnectTimeout=10 -i $SSH_KEY $SERVER "mkdir -p $remoteDir" 2>$null
        scp -o ConnectTimeout=10 -i $SSH_KEY $fullPath "${SERVER}:$remotePath" 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " ERRO!" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  X Nao encontrado: $file" -ForegroundColor Red
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
# ETAPA 2: Restart do servidor (sem precompile - só Ruby alterado)
# ================================================================
Write-Host "`nETAPA 2/2 - Limpando cache e reiniciando servidor..." -ForegroundColor Yellow

ssh -i $SSH_KEY $SERVER "cd $REMOTE_PATH; source ~/.bashrc; RAILS_ENV=production bundle exec rake tmp:cache:clear; sudo systemctl restart frotainstasolutions; sleep 3; sudo systemctl status frotainstasolutions --no-pager -l"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Correcoes aplicadas:" -ForegroundColor Cyan
    Write-Host "  1. Scope approved_in_current_month reescrito (SQL raw -> ActiveRecord joins)" -ForegroundColor White
    Write-Host "     Agora busca por associated_id em vez de LIKE fragil no audited_changes" -ForegroundColor White
    Write-Host "  2. Scope approved_in_period agora suporta ambos IDs (antigo=5, novo=7)" -ForegroundColor White
    Write-Host "  3. Constantes NEW_AUTORIZADA_ID e NEW_NOTA_FISCAL_INSERIDA_ID adicionadas" -ForegroundColor White
    Write-Host "  4. REQUIRED_ORDER_SERVICE_STATUSES expandido para ambas numeracoes" -ForegroundColor White
    Write-Host "  5. WebhookFinanceService.authorized? suporta ambos IDs" -ForegroundColor White
    Write-Host "  6. WebhookFinanceService.get_authorization_date busca por associated_id" -ForegroundColor White
    Write-Host ""
    Write-Host "Verificacao pos-deploy:" -ForegroundColor Yellow
    Write-Host "  - Acessar Faturas e verificar se OSs de Conceicao do Castelo aparecem" -ForegroundColor White
    Write-Host "  - Verificar o mes/ano correto no filtro" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  DEPLOY COM PROBLEMAS!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Verifique o status do servidor manualmente." -ForegroundColor Yellow
}
