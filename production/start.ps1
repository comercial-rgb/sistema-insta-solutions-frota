# Script para iniciar o sistema Insta Solutions localmente
# Certifique-se de ter o MySQL instalado e rodando

Write-Host "=== Iniciando Sistema Insta Solutions ===" -ForegroundColor Green
Write-Host ""

# Definir encoding
$env:LANG = "en_US.UTF-8"

# Verificar se o application.yml existe
if (-not (Test-Path "config\application.yml")) {
    Write-Host "ERRO: Arquivo config/application.yml não encontrado!" -ForegroundColor Red
    Write-Host "Por favor, copie config/application.yml.example para config/application.yml" -ForegroundColor Yellow
    Write-Host "e configure suas credenciais do banco de dados." -ForegroundColor Yellow
    exit 1
}

Write-Host "1. Verificando dependências..." -ForegroundColor Cyan
$bundleCheck = bundle check 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Algumas gems estão faltando. Tentando instalar..." -ForegroundColor Yellow
    bundle install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   AVISO: Alguns problemas ao instalar gems nativas." -ForegroundColor Yellow
        Write-Host "   Tentando continuar mesmo assim..." -ForegroundColor Yellow
    }
}

Write-Host "2. Configurando banco de dados..." -ForegroundColor Cyan
bundle exec rails db:create 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Banco de dados criado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "   Banco de dados já existe ou houve um erro." -ForegroundColor Yellow
}

Write-Host "3. Executando migrações..." -ForegroundColor Cyan
bundle exec rails db:migrate
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERRO ao executar migrações!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Iniciando servidor Rails na porta 3000 ===" -ForegroundColor Green
Write-Host "Acesse: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pressione Ctrl+C para parar o servidor" -ForegroundColor Yellow
Write-Host ""

bundle exec rails server -p 3000
