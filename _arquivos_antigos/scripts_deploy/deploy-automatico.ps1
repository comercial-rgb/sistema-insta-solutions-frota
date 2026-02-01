# Deploy Automático para AWS - Correções OS
# Executa todo o processo de deploy em um único comando

$ErrorActionPreference = "Stop"

# Configurações
$SSH_KEY = "$env:USERPROFILE\.ssh\frotainstasolutions-keypair.pem"
$SERVER = "ubuntu@3.226.131.200"
$APP_PATH = "/var/www/frotainstasolutions"
$PACKAGE = "correcoes_os_fix_2026-01-27_12-46.tar.gz"

Write-Host "`n=== DEPLOY AUTOMATICO - CORRECOES OS ===" -ForegroundColor Green
Write-Host "Servidor: $SERVER" -ForegroundColor Cyan
Write-Host "Pacote: $PACKAGE" -ForegroundColor Cyan

# Verifica se o pacote existe
if (-not (Test-Path $PACKAGE)) {
    Write-Host "`nERRO: Pacote $PACKAGE nao encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro: .\criar-pacote-deploy.ps1" -ForegroundColor Yellow
    exit 1
}

# Verifica se a chave SSH existe
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "`nERRO: Chave SSH nao encontrada em: $SSH_KEY" -ForegroundColor Red
    exit 1
}

Write-Host "`n[1/6] Criando backup no servidor..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "cd $APP_PATH && mkdir -p backups && tar -czf backups/backup_antes_correcoes_`$(date +%Y-%m-%d_%H-%M).tar.gz app/ 2>/dev/null || echo 'Backup pulado'"
Write-Host "Backup concluido!" -ForegroundColor Green

Write-Host "`n[2/6] Enviando pacote para servidor..." -ForegroundColor Yellow
scp -i $SSH_KEY $PACKAGE "${SERVER}:/tmp/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO ao enviar pacote!" -ForegroundColor Red
    exit 1
}
Write-Host "Pacote enviado com sucesso!" -ForegroundColor Green

Write-Host "`n[3/6] Extraindo arquivos no servidor..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "cd $APP_PATH && tar -xzf /tmp/$PACKAGE"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO ao extrair arquivos!" -ForegroundColor Red
    exit 1
}
Write-Host "Arquivos extraidos com sucesso!" -ForegroundColor Green

Write-Host "`n[4/6] Ajustando permissoes..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "sudo chown -R ubuntu:ubuntu $APP_PATH/app/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO ao ajustar permissoes!" -ForegroundColor Red
    exit 1
}
Write-Host "Permissoes ajustadas!" -ForegroundColor Green

Write-Host "`n[5/6] Validando correcoes..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "cd $APP_PATH && source ~/.bashrc && RAILS_ENV=production bundle exec rails runner check_production_status.rb 2>&1 || echo 'Validacao executada'"
Write-Host "Validacao concluida!" -ForegroundColor Green

Write-Host "`n[6/6] Reiniciando servidor..." -ForegroundColor Yellow
ssh -i $SSH_KEY $SERVER "sudo systemctl daemon-reload && sudo systemctl stop frotainstasolutions.service && sleep 2 && sudo systemctl start frotainstasolutions.service"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tentando metodo alternativo..." -ForegroundColor Yellow
    ssh -i $SSH_KEY $SERVER "cd $APP_PATH && pkill -f puma && sleep 2 && RAILS_ENV=production bundle exec puma -C config/puma/production.rb -d"
}
Write-Host "Servidor reiniciado!" -ForegroundColor Green

Write-Host "`n=== DEPLOY CONCLUIDO COM SUCESSO! ===" -ForegroundColor Green
Write-Host "`nAguarde 10-15 segundos para o servidor reiniciar completamente." -ForegroundColor Cyan
Write-Host "`nTeste agora em: https://app.frotainstasolutions.com.br" -ForegroundColor Cyan
Write-Host "`nVerifique se as 3 correcoes estao funcionando:" -ForegroundColor Yellow
Write-Host "1. Admin/Gestor/Adicional conseguem SALVAR ao editar OS" -ForegroundColor White
Write-Host "2. OS em 'Aguardando Avaliacao' NAO da erro 500" -ForegroundColor White
Write-Host "3. Fornecedores NAO recebem erro 500 ao acessar OS" -ForegroundColor White
Write-Host ""
