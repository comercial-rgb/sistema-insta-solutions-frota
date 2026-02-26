#!/usr/bin/env pwsh
# ================================================================
# Script de Deploy - Correcao OS Duplicada na Listagem
# Data: 25/02/2026
# ================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOY - Fix OS Duplicada (Triplicada)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$SSH_KEY = "$env:USERPROFILE\.ssh\frotainstasolutions-keypair.pem"
$SERVER = "ubuntu@3.226.131.200"
$REMOTE_PATH = "/var/www/frotainstasolutions/production"
$LOCAL_PATH = $PSScriptRoot

# ================================================================
# ARQUIVOS A ENVIAR
# ================================================================
$files = @(
    "app/controllers/order_services_controller.rb",
    "app/models/order_service.rb",
    "app/assets/javascripts/models/order_services.js"
)

# ================================================================
# ETAPA 1: Enviar arquivos
# ================================================================
Write-Host "ETAPA 1/3 - Enviando $($files.Count) arquivos para producao..." -ForegroundColor Yellow
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
# ETAPA 2: Precompile assets (JS foi alterado)
# ================================================================
Write-Host "`nETAPA 2/3 - Precompilando assets e limpando cache..." -ForegroundColor Yellow

ssh -i $SSH_KEY $SERVER "cd $REMOTE_PATH; source ~/.bashrc; RAILS_ENV=production bundle exec rake assets:precompile; RAILS_ENV=production bundle exec rake tmp:cache:clear; echo DONE_PRECOMPILE"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  OK - Assets precompilados com sucesso" -ForegroundColor Green
} else {
    Write-Host "  ERRO na precompilacao!" -ForegroundColor Red
    $continue = Read-Host "Continuar com o restart? (s/N)"
    if ($continue -ne "s" -and $continue -ne "S") {
        Write-Host "Deploy cancelado." -ForegroundColor Red
        exit 1
    }
}

# ================================================================
# ETAPA 3: Restart do servidor
# ================================================================
Write-Host "`nETAPA 3/3 - Reiniciando servidor..." -ForegroundColor Yellow

ssh -i $SSH_KEY $SERVER "sudo systemctl restart frotainstasolutions; sleep 3; sudo systemctl status frotainstasolutions --no-pager -l"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Correcoes aplicadas:" -ForegroundColor Cyan
    Write-Host "  1. .distinct em todas as queries de listagem (admin + gestor)" -ForegroundColor White
    Write-Host "  2. .not_complement nos batch updates (waiting_payment + make_payment)" -ForegroundColor White
    Write-Host "  3. Deduplicacao de IDs no JS e no controller" -ForegroundColor White
    Write-Host "  4. .distinct nos scopes by_proposal_provider_id e by_order_service_proposal_status_id" -ForegroundColor White
    Write-Host "  5. Contadores do sidebar usando .distinct.count" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  DEPLOY COM PROBLEMAS!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Verifique o status do servidor manualmente." -ForegroundColor Yellow
}
