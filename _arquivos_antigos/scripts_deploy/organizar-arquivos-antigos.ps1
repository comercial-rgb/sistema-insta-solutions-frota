# Script para organizar arquivos antigos do projeto
# Data: 2026-01-29

$ErrorActionPreference = "Stop"

Write-Host "`n=== Organizando Arquivos Antigos ===" -ForegroundColor Cyan

# Criar estrutura de pastas
$basePath = "c:\Users\Usuário\Desktop\sistema-insta-solutions\_arquivos_antigos"
$folders = @(
    "$basePath\backups_sql",
    "$basePath\scripts_sql_temporarios",
    "$basePath\scripts_teste",
    "$basePath\packages_antigos",
    "$basePath\documentacao_antiga",
    "$basePath\configs_temp"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force -ErrorAction SilentlyContinue | Out-Null
        if (Test-Path $folder) {
            Write-Host "OK Pasta criada: $folder" -ForegroundColor Green
        }
    }
}

# 1. BACKUPS SQL
Write-Host "`n[1/6] Movendo backups SQL..." -ForegroundColor Yellow
$sqlBackups = @(
    "backup_antes_atualizacao.sql",
    "backup_producao.sql",
    "banco_local_atual.sql",
    "banco_local_limpo.sql",
    "banco_producao_final_2026-01-26_19-20.sql",
    "banco_producao_final_2026-01-26_19-23.sql",
    "banco_producao_FINAL_COMPLETO_2026-01-26_19-58.sql",
    "banco_producao_FINAL_CORRIGIDO_2026-01-26_19-43.sql"
)
foreach ($file in $sqlBackups) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\backups_sql\" -Force
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
}

# 2. SCRIPTS SQL TEMPORÁRIOS
Write-Host "`n[2/6] Movendo scripts SQL temporários..." -ForegroundColor Yellow
$sqlScripts = @(
    "analyze_all_encoding_issues.sql",
    "check_blob.sql",
    "check_remaining.sql",
    "check_corrupted_files.sql",
    "encoding_final_report.sql",
    "find_encoding_issues.sql",
    "fix_all_encoding.sql",
    "fix_all_encoding_issues.sql",
    "fix_database.sql",
    "fix_encoding_drivers.sql",
    "fix_encoding_status.sql",
    "fix_encoding_texts.sql",
    "fix_final_encoding.sql",
    "fix_global_encoding.sql",
    "fix_keys.sql",
    "fix_last_vehicle.sql",
    "fix_massive_encoding.sql",
    "fix_os_status.sql",
    "show_tables.sql",
    "test_query.sql",
    "update_blobs.sql",
    "verify_encoding_fixes.sql",
    "verify_specific_words.sql",
    "relatorio_anexos_corrompidos.sql"
)
foreach ($file in $sqlScripts) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\scripts_sql_temporarios\" -Force
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
}

# 3. SCRIPTS DE TESTE
Write-Host "`n[3/6] Movendo scripts de teste..." -ForegroundColor Yellow
$testScripts = @(
    "check_production_status.rb",
    "fix_os_status.rb",
    "test_email.rb",
    "test_menu_real.rb",
    "validate_fixes.rb"
)
foreach ($file in $testScripts) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\scripts_teste\" -Force
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
}

# 4. PACKAGES ANTIGOS
Write-Host "`n[4/6] Movendo packages antigos..." -ForegroundColor Yellow
$packages = @(
    "codigo-local.tar.gz",
    "correcoes-insta-29-01.tar.gz",
    "correcoes_os_fix_2026-01-27_12-46.tar.gz",
    "deploy-completo.tar.gz",
    "release-latest.zip",
    "_release-test.zip",
    "_release-manifest.json"
)
foreach ($file in $packages) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\packages_antigos\" -Force
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
}

# 5. DOCUMENTAÇÃO ANTIGA
Write-Host "`n[5/6] Movendo documentação antiga..." -ForegroundColor Yellow
$oldDocs = @(
    "CORRECOES_APLICADAS.md",
    "CORREÇÕES_FINAIS.md",
    "CORREÇÕES_PENDENTES.md",
    "PASSOS_FINAIS.md",
    "VERIFICACAO_FINAL.md",
    "QUICK_DEPLOY.md",
    "DEPLOY_CORRECOES_RAPIDO.md",
    "MIGRATION_PLAN.md",
    "VEHICLE_MODELS_MIGRATION.md",
    "DEPLOY_ALTA_CARGA_1000_USUARIOS.md",
    "DEPLOY_AWS_COMPLETO.md",
    "DEPLOYMENT_CHECKLIST.md",
    "GRUPO_SERVICOS_COM_ITENS.md"
)
foreach ($file in $oldDocs) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\documentacao_antiga\" -Force
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
}

# 6. CONFIGS TEMP
Write-Host "`n[6/6] Movendo configs temporarios..." -ForegroundColor Yellow
$tempConfigs = @(
    "temp_application.yml",
    "temp_application_fixed.yml",
    ".rufus-scheduler.lock"
)
foreach ($file in $tempConfigs) {
    if (Test-Path $file) {
        Move-Item $file "$basePath\configs_temp\" -Force
        Write-Host "  OK $file" -ForegroundColor Gray
    }
}

# Criar arquivo índice
Write-Host "`n[7/7] Criando arquivo índice..." -ForegroundColor Yellow
$dataAtual = Get-Date -Format "dd/MM/yyyy HH:mm"
$indexContent = "# Indice de Arquivos Antigos`n"
$indexContent += "Data de Organizacao: $dataAtual`n`n"
$indexContent += "## Estrutura`n`n"
$indexContent += "### 1. backups_sql/`n"
$indexContent += "Backups do banco de dados de diferentes momentos da migracao`n`n"
$indexContent += "### 2. scripts_sql_temporarios/`n"
$indexContent += "Scripts SQL criados para correcoes pontuais`n`n"
$indexContent += "### 3. scripts_teste/`n"
$indexContent += "Scripts Ruby para testes e validacoes do sistema`n`n"
$indexContent += "### 4. packages_antigos/`n"
$indexContent += "Arquivos .tar.gz e .zip de deploys anteriores`n`n"
$indexContent += "### 5. documentacao_antiga/`n"
$indexContent += "Documentacao de correcoes e deploys ja realizados`n`n"
$indexContent += "### 6. configs_temp/`n"
$indexContent += "Arquivos de configuracao temporarios`n"

$indexContent | Out-File "$basePath\README.md" -Encoding UTF8
Write-Host "  OK README.md criado" -ForegroundColor Gray

Write-Host "`n=== Organizacao concluida ===" -ForegroundColor Green
$displayPath = $basePath
Write-Host "Arquivos movidos para: $displayPath" -ForegroundColor Cyan
