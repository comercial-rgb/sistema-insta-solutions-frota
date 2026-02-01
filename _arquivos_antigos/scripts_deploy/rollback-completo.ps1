# ROLLBACK COMPLETO - Voltar sistema ao estado funcional

$ErrorActionPreference = "Stop"

$SSH_KEY = "$env:USERPROFILE\.ssh\frotainstasolutions-keypair.pem"
$SERVER = "ubuntu@3.226.131.200"

Write-Host "`n=== EXECUTANDO ROLLBACK COMPLETO ===" -ForegroundColor Red
Write-Host "Voltando sistema ao estado funcional anterior..." -ForegroundColor Yellow

Write-Host "`n[1/4] Parando todos os processos Puma..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "pkill -9 -f puma"
Start-Sleep -Seconds 2
Write-Host "Processos parados!" -ForegroundColor Green

Write-Host "`n[2/4] Removendo arquivos problemáticos do deploy..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "cd /var/www/frotainstasolutions && rm -rf app/"
Write-Host "Arquivos removidos!" -ForegroundColor Green

Write-Host "`n[3/4] Reiniciando serviço systemd..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "sudo systemctl daemon-reload && sudo systemctl start frotainstasolutions.service"
Start-Sleep -Seconds 5
Write-Host "Serviço iniciado!" -ForegroundColor Green

Write-Host "`n[4/4] Verificando status..." -ForegroundColor Yellow
$status = ssh -i $SSH_KEY $SERVER "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000 2>&1"
Write-Host "Status HTTP: $status" -ForegroundColor Cyan

if ($status -eq "200" -or $status -eq "302") {
    Write-Host "`n=== ROLLBACK CONCLUIDO COM SUCESSO! ===" -ForegroundColor Green
    Write-Host "`nSistema deve estar funcionando em: https://app.frotainstasolutions.com.br" -ForegroundColor Green
    Write-Host "`nVamos aplicar as correcoes de forma DIFERENTE, sem quebrar o sistema." -ForegroundColor Yellow
} else {
    Write-Host "`n=== AVISO: Sistema ainda com problemas ===" -ForegroundColor Red
    Write-Host "Codigo HTTP: $status" -ForegroundColor Yellow
    Write-Host "`nPrecisamos investigar mais o servidor." -ForegroundColor Yellow
}
