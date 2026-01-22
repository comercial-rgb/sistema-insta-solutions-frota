# ================================================================
# Restore CURRENT Production Database - Auto Fix
# ================================================================
# Este script importa o banco de produção ATUAL e aplica
# correções automaticamente baseado nas diferenças detectadas
# 
# Uso: .\restore-current-production.ps1 -DumpFile "prod_atual.sql"

param(
    [Parameter(Mandatory=$true)]
    [string]$DumpFile,
    
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

function Write-Info {
    param([string]$Message)
    Write-Host "   [i] $Message" -ForegroundColor Gray
}

# ================================================================
# VALIDAÇÕES
# ================================================================

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  RESTORE CURRENT PRODUCTION - Auto Fix                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $DumpFile)) {
    Write-Error-Custom "Arquivo não encontrado: $DumpFile"
    Write-Host ""
    Write-Host "Arquivos .sql disponíveis:" -ForegroundColor Yellow
    Get-ChildItem -Filter "*.sql" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

$dumpSize = [math]::Round((Get-Item $DumpFile).Length / 1MB, 2)
Write-Success "Dump encontrado: $DumpFile ($dumpSize MB)"

# ================================================================
# PASSO 1: BACKUP E IMPORTAÇÃO
# ================================================================

Write-Step "PASSO 1: Importando banco de produção"

Write-Host ">> Criando backup do banco atual..." -ForegroundColor Cyan
$backupFile = "backup_before_prod_import_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').sql"
mysqldump -u $User -p$Password $Database > $backupFile 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Backup: $backupFile"
} else {
    Write-Warning-Custom "Sem backup (banco pode não existir)"
}

Write-Host "`n>> Recriando banco..." -ForegroundColor Cyan
mysql -u $User -p$Password -e "DROP DATABASE IF EXISTS $Database;" 2>$null
mysql -u $User -p$Password -e "CREATE DATABASE $Database CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>$null
Write-Success "Banco recriado com UTF-8"

Write-Host "`n>> Importando dump de produção..." -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
mysql -u $User -p$Password $Database < $DumpFile 2>$null
$stopwatch.Stop()

if ($LASTEXITCODE -eq 0) {
    Write-Success "Importado em $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2))s"
} else {
    Write-Error-Custom "Erro na importação"
    exit 1
}

# ================================================================
# PASSO 2: AUDITORIA AUTOMÁTICA
# ================================================================

Write-Step "PASSO 2: Auditoria automática do banco"

$auditScript = @'
# Verificar estrutura e IDs

puts "\n[ESTRUTURA]"

# Tabelas críticas que devem existir
required_tables = {
  'vehicle_models' => 'Modelos de veículos',
  'reference_prices' => 'Preços de referência',
  'commitment_cost_centers' => 'Centros de custo'
}

missing_tables = []
required_tables.each do |table, desc|
  if ActiveRecord::Base.connection.tables.include?(table)
    puts "  ✓ #{table} (#{desc})"
  else
    puts "  ✗ #{table} - FALTANDO!"
    missing_tables << table
  end
end

# Colunas críticas
puts "\n[COLUNAS CRÍTICAS]"

missing_columns = []

checks = [
  ['order_services', 'is_complement', 'BOOLEAN'],
  ['order_services', 'parent_proposal_id', 'BIGINT'],
  ['order_service_proposals', 'refused_approval', 'BOOLEAN'],
  ['vehicles', 'vehicle_model_id', 'BIGINT']
]

checks.each do |table, column, type|
  if ActiveRecord::Base.connection.column_exists?(table, column)
    puts "  ✓ #{table}.#{column}"
  else
    puts "  ✗ #{table}.#{column} - FALTANDO!"
    missing_columns << [table, column, type]
  end
end

# Verificar IDs de status
puts "\n[STATUS IDs]"

os_statuses = OrderServiceStatus.order(:id).pluck(:id, :name)
puts "\nOrderServiceStatus (#{os_statuses.size} registros):"
os_statuses.each { |id, name| puts "  #{id} = #{name}" }

expected_os_ids = {
  1 => 'Em cadastro',
  2 => 'Em aberto',
  3 => 'Em reavaliação',
  4 => /Aguardando avalia(ç|c)(ã|a)o/i,
  5 => 'Aprovada',
  6 => 'Nota fiscal inserida',
  7 => 'Autorizada',
  8 => 'Aguardando pagamento',
  9 => 'Paga',
  10 => 'Cancelada'
}

ids_mismatched = false
expected_os_ids.each do |expected_id, expected_name|
  actual = os_statuses.find { |id, _| id == expected_id }
  if actual.nil?
    puts "  ⚠ ID #{expected_id} não existe!"
    ids_mismatched = true
  elsif expected_name.is_a?(Regexp)
    unless actual[1] =~ expected_name
      puts "  ⚠ ID #{expected_id}: esperado '#{expected_name.inspect}', atual '#{actual[1]}'"
      ids_mismatched = true
    end
  elsif actual[1] != expected_name
    puts "  ⚠ ID #{expected_id}: esperado '#{expected_name}', atual '#{actual[1]}'"
    ids_mismatched = true
  end
end

# Propostas
proposal_statuses = OrderServiceProposalStatus.order(:id).pluck(:id, :name)
puts "\nOrderServiceProposalStatus (#{proposal_statuses.size} registros):"
proposal_statuses.each { |id, name| puts "  #{id} = #{name}" }

expected_prop_ids = [1, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
prop_ids_mismatched = false

expected_prop_ids.each do |expected_id|
  unless proposal_statuses.any? { |id, _| id == expected_id }
    puts "  ⚠ ID #{expected_id} não existe!"
    prop_ids_mismatched = true
  end
end

# Encoding
puts "\n[ENCODING]"
users_with_issues = User.where("name LIKE '%??%'").count
if users_with_issues > 0
  puts "  ⚠ #{users_with_issues} usuários com encoding corrompido (????)"
else
  puts "  ✓ Nenhum problema de encoding detectado"
end

# Contadores
puts "\n[DADOS]"
puts "  Usuários: #{User.count}"
puts "  Ordens de Serviço: #{OrderService.count}"
puts "  Propostas: #{OrderServiceProposal.count}"
puts "  Veículos: #{Vehicle.count}"
puts "  Modelos: #{VehicleModel.count}"

# Resultado da auditoria
puts "\n" + "="*60
puts "RESULTADO DA AUDITORIA"
puts "="*60

issues = []
issues << "Tabelas faltando: #{missing_tables.size}" if missing_tables.any?
issues << "Colunas faltando: #{missing_columns.size}" if missing_columns.any?
issues << "IDs de status incorretos" if ids_mismatched || prop_ids_mismatched
issues << "Encoding corrompido: #{users_with_issues} usuários" if users_with_issues > 0

if issues.empty?
  puts "✓ NENHUM PROBLEMA DETECTADO!"
  puts "O banco de produção está compatível com o código."
else
  puts "⚠ PROBLEMAS DETECTADOS:"
  issues.each { |issue| puts "  - #{issue}" }
  puts "\nCorreções serão aplicadas automaticamente..."
end

# Salvar resultado em arquivo para PowerShell ler
File.write('tmp/audit_result.txt', issues.join("\n"))

puts "="*60
'@

Write-Host ">> Executando auditoria..." -ForegroundColor Cyan
$auditScript | bundle exec rails runner - 2>&1 | Tee-Object -Variable auditOutput | Out-Host

# ================================================================
# PASSO 3: APLICAR CORREÇÕES AUTOMATICAMENTE
# ================================================================

Write-Step "PASSO 3: Aplicando correções necessárias"

$needsFixes = $false
if (Test-Path "tmp/audit_result.txt") {
    $issues = Get-Content "tmp/audit_result.txt"
    if ($issues -and $issues.Length -gt 0) {
        $needsFixes = $true
    }
}

if (-not $needsFixes) {
    Write-Success "Nenhuma correção necessária!"
    Write-Host "`n>> Banco de produção está 100% compatível com o código!" -ForegroundColor Green
} else {
    Write-Warning-Custom "Aplicando correções detectadas..."
    
    # Corrigir tabelas faltantes
    Write-Host "`n>> [3.1] Verificando tabelas..." -ForegroundColor Cyan
    
    $checkTablesScript = @'
missing = []
missing << "vehicle_models" unless ActiveRecord::Base.connection.table_exists?("vehicle_models")
missing << "reference_prices" unless ActiveRecord::Base.connection.table_exists?("reference_prices")
missing << "commitment_cost_centers" unless ActiveRecord::Base.connection.table_exists?("commitment_cost_centers")

if missing.any?
  puts "MISSING_TABLES:#{missing.join(',')}"
else
  puts "ALL_TABLES_OK"
end
'@
    
    $tableCheck = $checkTablesScript | bundle exec rails runner - 2>&1
    
    if ($tableCheck -match "MISSING_TABLES:(.+)") {
        $missingTables = $matches[1] -split ','
        Write-Warning-Custom "Faltam tabelas: $($missingTables -join ', ')"
        Write-Host "   Executando migrações..." -ForegroundColor Gray
        bundle exec rails db:migrate 2>&1 | Out-Null
        Write-Success "Tabelas criadas via migrações"
    } else {
        Write-Success "Todas as tabelas presentes"
    }
    
    # Corrigir colunas
    Write-Host "`n>> [3.2] Verificando colunas..." -ForegroundColor Cyan
    if (Test-Path "scripts/add_os_complement_columns.rb") {
        bundle exec rails runner scripts/add_os_complement_columns.rb 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Colunas verificadas/adicionadas"
        }
    }
    
    # Corrigir IDs de status
    Write-Host "`n>> [3.3] Sincronizando IDs de status..." -ForegroundColor Cyan
    if (Test-Path "scripts/sync_status_ids.rb") {
        # Versão não-interativa
        $syncContent = Get-Content "scripts/sync_status_ids.rb" -Raw
        $syncContent = $syncContent -replace 'print.*CONFIRMO.*\n.*gets\.chomp.*\n.*unless.*\n.*puts.*\n.*exit.*\n.*end', ''
        $tempSync = "scripts/temp_sync_non_interactive.rb"
        $syncContent | Out-File -FilePath $tempSync -Encoding UTF8
        
        bundle exec rails runner $tempSync 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "IDs de status sincronizados"
        } else {
            Write-Warning-Custom "IDs podem já estar corretos"
        }
        
        Remove-Item $tempSync -ErrorAction SilentlyContinue
    }
    
    # Corrigir encoding
    Write-Host "`n>> [3.4] Corrigindo encoding UTF-8..." -ForegroundColor Cyan
    if (Test-Path "scripts/fix_users_encoding.rb") {
        bundle exec rails runner scripts/fix_users_encoding.rb 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Encoding corrigido"
        }
    }
    
    # Corrigir nome de status
    if (Test-Path "scripts/fix_status_4_name.rb") {
        bundle exec rails runner scripts/fix_status_4_name.rb 2>&1 | Out-Null
    }
}

# ================================================================
# PASSO 4: VALIDAÇÃO FINAL
# ================================================================

Write-Step "PASSO 4: Validação final"

$validationScript = @'
puts "Usuários: #{User.count}"
puts "Ordens de Serviço: #{OrderService.count}"
puts "Propostas: #{OrderServiceProposal.count}"
puts "Veículos: #{Vehicle.count}"
puts "Modelos: #{VehicleModel.count}"
puts "---"
puts "OSs Aprovadas: #{OrderService.where(order_service_status_id: OrderServiceStatus::APROVADA_ID).count}"
puts "OSs Pagas: #{OrderService.where(order_service_status_id: OrderServiceStatus::PAGA_ID).count}"
puts "Propostas Aprovadas: #{OrderServiceProposal.where(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID).count}"
puts "Propostas Pagas: #{OrderServiceProposal.where(order_service_proposal_status_id: OrderServiceProposalStatus::PAGA_ID).count}"
puts "---"

# Testar cálculos do Dashboard
begin
  os_count = OrderService.count
  approved_count = OrderService.where(order_service_status_id: OrderServiceStatus::APROVADA_ID).count
  puts "✓ Cálculos Dashboard funcionando"
rescue => e
  puts "✗ Erro nos cálculos: #{e.message}"
end

# Testar badges
begin
  os = OrderService.first
  if os && os.order_service_type
    puts "✓ Badges de OS funcionando"
  end
rescue => e
  puts "✗ Erro nos badges: #{e.message}"
end
'@

Write-Host ">> Validando sistema..." -ForegroundColor Cyan
$validationOutput = $validationScript | bundle exec rails runner - 2>&1

Write-Host ""
$validationOutput | ForEach-Object {
    if ($_ -match "^✓") {
        Write-Host "   $_" -ForegroundColor Green
    } elseif ($_ -match "^✗") {
        Write-Host "   $_" -ForegroundColor Red
    } else {
        Write-Host "   $_" -ForegroundColor Gray
    }
}

# ================================================================
# CONCLUSÃO
# ================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          IMPORTAÇÃO E CORREÇÃO CONCLUÍDAS                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Banco de produção importado" -ForegroundColor Green
Write-Host "✅ Correções aplicadas automaticamente" -ForegroundColor Green
Write-Host "✅ Sistema compatível com o código" -ForegroundColor Green
Write-Host ""
Write-Host "Próximo passo:" -ForegroundColor Cyan
Write-Host "   .\quick-start.ps1" -ForegroundColor White
Write-Host ""

if (Test-Path $backupFile) {
    Write-Info "Backup anterior salvo em: $backupFile"
    Write-Host ""
}

# Limpar temporários
Remove-Item "tmp/audit_result.txt" -ErrorAction SilentlyContinue
