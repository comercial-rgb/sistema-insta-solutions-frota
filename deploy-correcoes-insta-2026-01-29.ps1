# ================================================================
# Script de Deploy - Correções 29/01/2026
# ================================================================
# Descrição: Deploy das correções de:
#   - Fornecedor com Nome Fantasia
#   - Empenho com múltiplos centros de custo (modal)
#   - Veículo otimizado (apenas placa)
#   - Services com importação/exportação Excel melhorada

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ServerUser = "ubuntu",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHKey = "",
    
    [switch]$DryRun,
    [switch]$SkipBackup
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   DEPLOY - Correções Insta Solutions - 29/01/2026" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar parâmetros
if ([string]::IsNullOrEmpty($ServerIP)) {
    Write-Host "⚠️  IP do servidor não fornecido!" -ForegroundColor Yellow
    Write-Host ""
    $ServerIP = Read-Host "Digite o IP do servidor de produção"
    if ([string]::IsNullOrEmpty($ServerIP)) {
        Write-Host "❌ IP é obrigatório!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📋 Informações do Deploy:" -ForegroundColor Green
Write-Host "   Servidor: $ServerIP" -ForegroundColor Gray
Write-Host "   Usuário: $ServerUser" -ForegroundColor Gray
Write-Host "   Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
if (-not [string]::IsNullOrEmpty($SSHKey)) {
    Write-Host "   SSH Key: $SSHKey" -ForegroundColor Gray
}
Write-Host ""

# Arquivos que serão enviados (pasta production)
$filesToDeploy = @(
    # Grids
    "production/app/grids/order_services_grid.rb",
    
    # Views - Order Services
    "production/app/views/order_services/_show_vehicle_data.html.erb",
    "production/app/views/order_services/_show_commitment_data.html.erb",
    "production/app/views/order_services/modals/_show_cost_centers.html.erb",
    
    # Controllers
    "production/app/controllers/services_controller.rb",
    "production/app/controllers/services_import_controller.rb",
    
    # Views - Services Import
    "production/app/views/services_import/new.html.erb"
)

Write-Host "📦 Arquivos a serem enviados: $($filesToDeploy.Count)" -ForegroundColor Yellow
foreach ($file in $filesToDeploy) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file [NÃO ENCONTRADO]" -ForegroundColor Red
    }
}
Write-Host ""

# Verificar se todos os arquivos existem
$missingFiles = @()
foreach ($file in $filesToDeploy) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Arquivos não encontrados:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "💡 Verifique se você está executando o script na raiz do projeto" -ForegroundColor Yellow
    exit 1
}

if ($DryRun) {
    Write-Host "🔍 [DRY RUN] Modo de teste - nenhuma alteração será feita" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "✅ Validação concluída!" -ForegroundColor Green
    exit 0
}

# Criar pacote com timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$packageName = "correcoes_insta_$timestamp.tar.gz"

Write-Host "📦 Criando pacote de correções..." -ForegroundColor Yellow

# Criar estrutura temporária para manter a hierarquia de pastas
$tempDir = "temp_deploy_$timestamp"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

foreach ($file in $filesToDeploy) {
    $destination = Join-Path $tempDir ($file -replace "^production/", "")
    $destinationDir = Split-Path $destination -Parent
    
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    
    Copy-Item $file $destination -Force
}

# Criar pacote
Push-Location $tempDir
tar -czf "../$packageName" * 2>&1 | Out-Null
Pop-Location

# Limpar diretório temporário
Remove-Item $tempDir -Recurse -Force

if (Test-Path $packageName) {
    $packageSize = (Get-Item $packageName).Length / 1KB
    $sizeFormatted = [math]::Round($packageSize, 2)
    Write-Host "   ✅ Pacote criado: $packageName ($sizeFormatted KB)" -ForegroundColor Green
} else {
    Write-Host "❌ Falha ao criar pacote" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   INSTRUÇÕES PARA DEPLOY" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Construir comando SSH
$sshCommand = if ([string]::IsNullOrEmpty($SSHKey)) {
    "ssh $ServerUser@$ServerIP"
} else {
    "ssh -i `"$SSHKey`" $ServerUser@$ServerIP"
}

$scpCommand = if ([string]::IsNullOrEmpty($SSHKey)) {
    "scp $packageName ${ServerUser}@${ServerIP}:/tmp/"
} else {
    "scp -i `"$SSHKey`" $packageName ${ServerUser}@${ServerIP}:/tmp/"
}

Write-Host "1️⃣ FAZER BACKUP NO SERVIDOR (Recomendado)" -ForegroundColor Cyan
Write-Host ""
Write-Host "   $sshCommand" -ForegroundColor Yellow
Write-Host ""
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   tar -czf backups/backup_antes_correcoes_$timestamp.tar.gz \\" -ForegroundColor Yellow
Write-Host "     app/grids/order_services_grid.rb \\" -ForegroundColor Yellow
Write-Host "     app/views/order_services/ \\" -ForegroundColor Yellow
Write-Host "     app/controllers/services_controller.rb \\" -ForegroundColor Yellow
Write-Host "     app/controllers/services_import_controller.rb \\" -ForegroundColor Yellow
Write-Host "     app/views/services_import/" -ForegroundColor Yellow
Write-Host ""
Write-Host "   echo '✅ Backup criado!'" -ForegroundColor Yellow
Write-Host ""

Write-Host "2️⃣ ENVIAR PACOTE DE CORREÇÕES" -ForegroundColor Cyan
Write-Host ""
Write-Host "   $scpCommand" -ForegroundColor Yellow
Write-Host ""

Write-Host "3️⃣ EXTRAIR NO SERVIDOR" -ForegroundColor Cyan
Write-Host ""
Write-Host "   $sshCommand" -ForegroundColor Yellow
Write-Host ""
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   tar -xzf /tmp/$packageName" -ForegroundColor Yellow
Write-Host "   chown -R ${ServerUser}:${ServerUser} app/" -ForegroundColor Yellow
Write-Host ""
Write-Host "   echo '✅ Arquivos extraídos!'" -ForegroundColor Yellow
Write-Host ""

Write-Host "4️⃣ REINICIAR SERVIDOR" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Opção 1: Systemd Service" -ForegroundColor Gray
Write-Host "   sudo systemctl restart puma_frotainstasolutions" -ForegroundColor Yellow
Write-Host ""
Write-Host "   # Opção 2: Service alternativo" -ForegroundColor Gray
Write-Host "   sudo systemctl restart frotainstasolutions" -ForegroundColor Yellow
Write-Host ""
Write-Host "   # Opção 3: Puma manualmente" -ForegroundColor Gray
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   bundle exec pumactl restart" -ForegroundColor Yellow
Write-Host ""

Write-Host "5️⃣ VERIFICAR LOGS" -ForegroundColor Cyan
Write-Host ""
Write-Host "   tail -f /var/www/frotainstasolutions/log/production.log" -ForegroundColor Yellow
Write-Host ""

Write-Host "6️⃣ TESTAR NO NAVEGADOR" -ForegroundColor Cyan
Write-Host ""
Write-Host "   ✓ Acessar a aplicação" -ForegroundColor Gray
Write-Host "   ✓ Verificar coluna Fornecedor (deve mostrar nome fantasia)" -ForegroundColor Gray
Write-Host "   ✓ Verificar coluna Empenho (lupa quando > 1 centro de custo)" -ForegroundColor Gray
Write-Host "   ✓ Verificar coluna Veículo (apenas placa com lupa)" -ForegroundColor Gray
Write-Host "   ✓ Testar download/upload de Excel em Services" -ForegroundColor Gray
Write-Host ""

Write-Host "================================================================" -ForegroundColor Red
Write-Host "   ROLLBACK (Se necessário)" -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "   cd /var/www/frotainstasolutions" -ForegroundColor Yellow
Write-Host "   tar -xzf backups/backup_antes_correcoes_$timestamp.tar.gz" -ForegroundColor Yellow
Write-Host "   chown -R ${ServerUser}:${ServerUser} app/" -ForegroundColor Yellow
Write-Host "   sudo systemctl restart puma_frotainstasolutions" -ForegroundColor Yellow
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ PACOTE PRONTO: $packageName" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Execute o passo 1 (backup) via SSH" -ForegroundColor Gray
Write-Host "   2. Execute o passo 2 (enviar pacote) no PowerShell local" -ForegroundColor Gray
Write-Host "   3. Execute os passos 3-5 via SSH" -ForegroundColor Gray
Write-Host "   4. Teste a aplicação (passo 6)" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Salvar comandos em arquivo para referência
$commandsFile = "comandos_deploy_$timestamp.txt"
@"
================================================================
COMANDOS DE DEPLOY - $timestamp
================================================================

1. BACKUP NO SERVIDOR:
$sshCommand
cd /var/www/frotainstasolutions
mkdir -p backups
tar -czf backups/backup_antes_correcoes_$timestamp.tar.gz app/grids/order_services_grid.rb app/views/order_services/ app/controllers/services_controller.rb app/controllers/services_import_controller.rb app/views/services_import/

2. ENVIAR PACOTE:
$scpCommand

3. EXTRAIR NO SERVIDOR:
$sshCommand
cd /var/www/frotainstasolutions
tar -xzf /tmp/$packageName
chown -R ${ServerUser}:${ServerUser} app/

4. REINICIAR:
sudo systemctl restart puma_frotainstasolutions

5. VERIFICAR LOGS:
tail -f /var/www/frotainstasolutions/log/production.log

ROLLBACK:
cd /var/www/frotainstasolutions
tar -xzf backups/backup_antes_correcoes_$timestamp.tar.gz
chown -R ${ServerUser}:${ServerUser} app/
sudo systemctl restart puma_frotainstasolutions

================================================================
"@ | Out-File -FilePath $commandsFile -Encoding UTF8

Write-Host "💾 Comandos salvos em: $commandsFile" -ForegroundColor Cyan
Write-Host ""
