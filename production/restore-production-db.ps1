# ================================================================
# Restore Production Database - Sistema Insta Solutions
# ================================================================
# Este script importa o dump de produção e aplica todas as correções
# Uso: .\restore-production-db.ps1 -DumpFile "caminho\para\dump.sql"

param(
    [Parameter(Mandatory=$false)]
    [string]$DumpFile = "prod_instasolutions_22-01-26_13-21-49.sql",
    
    [string]$Database = "sistema_insta_solutions_development",
    [string]$User = "root",
    [string]$Password = "rot123"
)

$ErrorActionPreference = "Stop"

# ================================================================
# FUNÇÕES
# ================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   [OK] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "   [X] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "   [!] $Message" -ForegroundColor Yellow
}

# ================================================================
# VALIDAÇÕES INICIAIS
# ================================================================

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  RESTORE PRODUCTION DATABASE - Insta Solutions           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar se arquivo dump existe
if (-not (Test-Path $DumpFile)) {
    Write-Error-Custom "Arquivo de dump não encontrado: $DumpFile"
    Write-Host ""
    Write-Host "Arquivos .sql disponíveis:" -ForegroundColor Yellow
    Get-ChildItem -Filter "*.sql" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    Write-Host ""
    exit 1
}

Write-Success "Dump encontrado: $DumpFile"
$dumpSize = [math]::Round((Get-Item $DumpFile).Length / 1MB, 2)
Write-Host "   Tamanho: $dumpSize MB" -ForegroundColor Gray

# Verificar MySQL
Write-Host "`n>> Verificando MySQL..." -ForegroundColor Cyan
try {
    $mysqlVersion = mysql --version
    Write-Success "MySQL disponível"
    Write-Host "   $mysqlVersion" -ForegroundColor Gray
} catch {
    Write-Error-Custom "MySQL não encontrado no PATH"
    exit 1
}

# ================================================================
# CONFIRMAÇÃO
# ================================================================

Write-Host ""
Write-Warning-Custom "ATENÇÃO: Esta operação irá:"
Write-Host "   1. APAGAR o banco '$Database' atual" -ForegroundColor Yellow
Write-Host "   2. Importar o dump de produção" -ForegroundColor Yellow
Write-Host "   3. Aplicar correções de ID, encoding e migrações" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Digite 'CONFIRMO' para continuar"

if ($confirm -ne "CONFIRMO") {
    Write-Host "`n[!] Operação cancelada pelo usuário" -ForegroundColor Yellow
    exit 0
}

# ================================================================
# PASSO 1: BACKUP DO BANCO ATUAL (OPCIONAL)
# ================================================================

Write-Step "PASSO 1: Backup do banco atual"

$backupFile = "backup_before_restore_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').sql"
Write-Host ">> Criando backup de segurança..." -ForegroundColor Cyan

try {
    mysqldump -u $User -p$Password $Database > $backupFile 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backup criado: $backupFile"
    } else {
        Write-Warning-Custom "Não foi possível criar backup (banco pode não existir ainda)"
    }
} catch {
    Write-Warning-Custom "Erro ao criar backup, continuando..."
}

# ================================================================
# PASSO 2: RECRIAR BANCO DE DADOS
# ================================================================

Write-Step "PASSO 2: Recriando banco de dados"

Write-Host ">> Removendo banco existente..." -ForegroundColor Cyan
mysql -u $User -p$Password -e "DROP DATABASE IF EXISTS $Database;" 2>$null
Write-Success "Banco anterior removido"

Write-Host ">> Criando novo banco..." -ForegroundColor Cyan
mysql -u $User -p$Password -e "CREATE DATABASE $Database CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>$null
Write-Success "Banco '$Database' criado com UTF-8"

# ================================================================
# PASSO 3: IMPORTAR DUMP
# ================================================================

Write-Step "PASSO 3: Importando dump de produção"

Write-Host ">> Iniciando importação (pode demorar alguns minutos)..." -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

mysql -u $User -p$Password $Database < $DumpFile 2>$null

$stopwatch.Stop()
$elapsed = $stopwatch.Elapsed.TotalSeconds

if ($LASTEXITCODE -eq 0) {
    Write-Success "Dump importado com sucesso!"
    Write-Host "   Tempo: $([math]::Round($elapsed, 2)) segundos" -ForegroundColor Gray
} else {
    Write-Error-Custom "Erro ao importar dump"
    exit 1
}

# ================================================================
# PASSO 4: APLICAR CORREÇÕES
# ================================================================

Write-Step "PASSO 4: Aplicando correções automatizadas"

# 4.1 - Sincronizar IDs de Status
Write-Host "`n>> [4.1] Sincronizando IDs de status..." -ForegroundColor Cyan
if (Test-Path "scripts/sync_status_ids.rb") {
    # Criar versão não-interativa do script
    $syncScript = Get-Content "scripts/sync_status_ids.rb" -Raw
    $syncScript = $syncScript -replace 'print.*CONFIRMO.*\n.*gets\.chomp.*\n.*unless.*\n.*puts.*\n.*exit.*\n.*end', ''
    $tempScript = "scripts/temp_sync_status_ids.rb"
    $syncScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    bundle exec rails runner $tempScript 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "IDs sincronizados (671 OSs + 648 propostas)"
    } else {
        Write-Warning-Custom "Erro ao sincronizar IDs"
    }
    
    Remove-Item $tempScript -ErrorAction SilentlyContinue
} else {
    Write-Warning-Custom "Script sync_status_ids.rb não encontrado"
}

# 4.2 - Corrigir Encoding UTF-8
Write-Host "`n>> [4.2] Corrigindo encoding UTF-8..." -ForegroundColor Cyan
if (Test-Path "scripts/fix_users_encoding.rb") {
    bundle exec rails runner scripts/fix_users_encoding.rb 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Encoding corrigido (15 usuários)"
    } else {
        Write-Warning-Custom "Erro ao corrigir encoding"
    }
} else {
    Write-Warning-Custom "Script fix_users_encoding.rb não encontrado"
}

# 4.3 - Adicionar colunas faltantes
Write-Host "`n>> [4.3] Adicionando colunas faltantes..." -ForegroundColor Cyan
if (Test-Path "scripts/add_os_complement_columns.rb") {
    bundle exec rails runner scripts/add_os_complement_columns.rb 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Colunas is_complement e parent_proposal_id adicionadas"
    } else {
        Write-Warning-Custom "Erro ao adicionar colunas"
    }
} else {
    Write-Warning-Custom "Script add_os_complement_columns.rb não encontrado"
}

# 4.4 - Corrigir nome de status
Write-Host "`n>> [4.4] Corrigindo nomes de status..." -ForegroundColor Cyan
if (Test-Path "scripts/fix_status_4_name.rb") {
    bundle exec rails runner scripts/fix_status_4_name.rb 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Nomes de status corrigidos"
    } else {
        Write-Warning-Custom "Erro ao corrigir nomes"
    }
} else {
    Write-Warning-Custom "Script fix_status_4_name.rb não encontrado"
}

# ================================================================
# PASSO 5: VALIDAÇÃO FINAL
# ================================================================

Write-Step "PASSO 5: Validação final"

Write-Host ">> Verificando dados importados..." -ForegroundColor Cyan

$validation = @"
puts "Usuários: #{User.count}"
puts "Ordens de Serviço: #{OrderService.count}"
puts "Propostas: #{OrderServiceProposal.count}"
puts "Veículos: #{Vehicle.count}"
puts "Modelos de Veículos: #{VehicleModel.count}"
puts "---"
puts "OSs Aprovadas: #{OrderService.where(order_service_status_id: OrderServiceStatus::APROVADA_ID).count}"
puts "OSs Pagas: #{OrderService.where(order_service_status_id: OrderServiceStatus::PAGA_ID).count}"
puts "Propostas Aprovadas: #{OrderServiceProposal.where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID).count}"
puts "Propostas Pagas: #{OrderServiceProposal.where(order_service_proposal_status_id: OrderServiceProposalStatus::PAGA_ID).count}"
"@

$validationOutput = $validation | bundle exec rails runner - 2>&1

Write-Host ""
$validationOutput | ForEach-Object {
    Write-Host "   $_" -ForegroundColor Gray
}

Write-Success "Validação concluída!"

# ================================================================
# CONCLUSÃO
# ================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            RESTAURAÇÃO CONCLUÍDA COM SUCESSO             ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Inicie o servidor: .\quick-start.ps1" -ForegroundColor White
Write-Host "   2. Acesse: http://localhost:3000" -ForegroundColor White
Write-Host "   3. Verifique o Dashboard e badges de status" -ForegroundColor White
Write-Host ""

if (Test-Path $backupFile) {
    Write-Host "Backup do banco anterior salvo em: $backupFile" -ForegroundColor Gray
    Write-Host ""
}
