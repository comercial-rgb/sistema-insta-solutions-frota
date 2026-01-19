# ================================================================
# Quick Start - Sistema Insta Solutions (Otimizado)
# ================================================================
# Uso: .\quick-start.ps1  [-SkipMigrations] [-Port 3000]

param(
    [switch]$SkipMigrations,
    [int]$Port = 3000,
    [switch]$Debug
)

$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'  # Acelera downloads

# ================================================================
# FUNÇÕES AUXILIARES
# ================================================================

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Test-ServerRunning {
    param([int]$Port)
    $tcpConnection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    return $tcpConnection
}

function Stop-RubyProcesses {
    Write-Host "`n>> Verificando processos Ruby..." -ForegroundColor Yellow
    $rubyProcesses = Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}
    if ($rubyProcesses) {
        Write-Host "   Parando $($rubyProcesses.Count) processo(s)..." -ForegroundColor Gray
        $rubyProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "   [OK] Finalizado" -ForegroundColor Green
    } else {
        Write-Host "   [OK] Nada para parar" -ForegroundColor Green
    }
}

# ================================================================
# INÍCIO
# ================================================================

Clear-Host
if ($Debug) {
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "   QUICK START - Sistema Insta Solutions" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Quick Start - InstaSolutions" -ForegroundColor Cyan
}

# Assinatura do script (ajuda a confirmar se o arquivo certo foi enviado/rodado)
try {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        $scriptHash = (Get-FileHash -Algorithm SHA256 -Path $scriptPath).Hash.Substring(0, 12)
        if ($Debug) {
            Write-Host ("   Build: {0}" -f $scriptHash) -ForegroundColor DarkGray
            Write-Host ""
        }
    }
} catch {
    # ignore
}

# Verificar se já tem servidor rodando
if (Test-ServerRunning -Port $Port) {
    Write-Host "[!] AVISO: Servidor já está rodando na porta $Port" -ForegroundColor Yellow
    $response = Read-Host "Deseja reiniciar? (S/N)"
    if ($response -ne "S") {
        Write-Host "`n[OK] Servidor já está ativo em http://localhost:$Port" -ForegroundColor Green
        exit 0
    }
    Stop-RubyProcesses
}

# Verificar config
if (-not (Test-Path "config\application.yml")) {
    Write-Host "[X] ERRO: config/application.yml não encontrado!" -ForegroundColor Red
    Write-Host "   Execute: Copy-Item config\application.yml.example config\application.yml" -ForegroundColor Yellow
    exit 1
}

# Verificar conexão com banco
Write-Host ">> Testando conexão com banco de dados..." -ForegroundColor Cyan
$dbTest = bundle exec rails runner "ActiveRecord::Base.connection" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   [!] Banco pode não estar acessível, mas continuando..." -ForegroundColor Yellow
} else {
    Write-Host "   [OK] Banco de dados conectado!" -ForegroundColor Green
}

# Migrações (opcional)
if (-not $SkipMigrations) {
    Write-Host "`n>> Verificando migrações..." -ForegroundColor Cyan
    $migrationCheck = bundle exec rails db:migrate:status 2>&1 | Select-String "down"
    if ($migrationCheck) {
        Write-Host "   Executando migrações pendentes..." -ForegroundColor Yellow
        bundle exec rails db:migrate 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [OK] Migrações aplicadas!" -ForegroundColor Green
        } else {
            Write-Host "   [!] Erro nas migrações, mas continuando..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [OK] Nenhuma migração pendente" -ForegroundColor Green
    }
}

# Limpar cache Rails (acelera inicialização)
if (Test-Path "tmp\cache") {
    Write-Host "`n>> Limpando cache..." -ForegroundColor Cyan
    Remove-Item -Path "tmp\cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Cache limpo!" -ForegroundColor Green
}

# Iniciar servidor
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "          INICIANDO SERVIDOR RAILS" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "   URL: http://localhost:$Port" -ForegroundColor Cyan
if ($Debug) {
    Write-Host "   Modo: Development" -ForegroundColor Gray
    Write-Host ""
}
Write-Host ">> Pressione Ctrl+C para parar o servidor <<" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================================" -ForegroundColor Gray
Write-Host ""

# Executar servidor
bundle exec rails server -p $Port
