#!/bin/bash
# =========================================================
# Script de Backup Automático
# =========================================================
# Frota Insta Solutions
# app.frotainstasolutions.com.br
# =========================================================

# Configurações
BACKUP_DIR="/backups/frotainstasolutions"
APP_DIR="/var/www/frotainstasolutions/production"
DB_NAME="sistema_insta_solutions_production"
DB_USER="instasolutions"
DB_PASS="SUA_SENHA_AQUI"  # ⚠️ ALTERAR COM A SENHA REAL
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"
LOG_FILE="/var/log/backup-frotainstasolutions.log"

# Configurações de retenção
DAYS_TO_KEEP=30  # Manter backups dos últimos 30 dias
S3_BUCKET=""     # Opcional: bucket S3 para backup remoto

# =========================================================
# Funções
# =========================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# =========================================================
# Início do Backup
# =========================================================

log_message "=========================================="
log_message "Iniciando backup do banco de dados..."
log_message "=========================================="

# Criar diretório de backup se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log_message "Diretório de backup criado: $BACKUP_DIR"
fi

# Verificar se MySQL está rodando
if ! systemctl is-active --quiet mysql; then
    log_message "ERRO: MySQL não está rodando!"
    exit 1
fi

# Fazer backup do banco de dados
log_message "Executando mysqldump..."
if mysqldump -u "$DB_USER" -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "$DB_NAME" > "$BACKUP_FILE" 2>> "$LOG_FILE"; then
    
    log_message "Backup SQL criado: $BACKUP_FILE"
    
    # Verificar tamanho do arquivo
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_message "Tamanho do backup: $FILE_SIZE"
    
else
    log_message "ERRO: Falha ao criar backup do banco de dados!"
    exit 1
fi

# Comprimir backup
log_message "Comprimindo backup..."
if gzip "$BACKUP_FILE"; then
    BACKUP_FILE_GZ="${BACKUP_FILE}.gz"
    log_message "Backup comprimido: $BACKUP_FILE_GZ"
    
    # Tamanho comprimido
    FILE_SIZE_GZ=$(du -h "$BACKUP_FILE_GZ" | cut -f1)
    log_message "Tamanho comprimido: $FILE_SIZE_GZ"
else
    log_message "ERRO: Falha ao comprimir backup!"
    exit 1
fi

# =========================================================
# Backup dos Arquivos da Aplicação (opcional)
# =========================================================

# Fazer backup dos arquivos de configuração e storage
log_message "Criando backup de arquivos da aplicação..."

CONFIG_BACKUP="$BACKUP_DIR/config_$DATE.tar.gz"
tar -czf "$CONFIG_BACKUP" \
    -C "$APP_DIR" \
    config/application.yml \
    config/database.yml \
    storage/ \
    public/uploads/ \
    2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    CONFIG_SIZE=$(du -h "$CONFIG_BACKUP" | cut -f1)
    log_message "Backup de arquivos criado: $CONFIG_BACKUP ($CONFIG_SIZE)"
else
    log_message "AVISO: Falha ao criar backup de arquivos"
fi

# =========================================================
# Upload para S3 (opcional)
# =========================================================

if [ -n "$S3_BUCKET" ]; then
    log_message "Enviando backup para S3: $S3_BUCKET"
    
    aws s3 cp "$BACKUP_FILE_GZ" "s3://$S3_BUCKET/backups/database/" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "Backup enviado para S3 com sucesso"
    else
        log_message "AVISO: Falha ao enviar backup para S3"
    fi
    
    # Upload backup de arquivos
    if [ -f "$CONFIG_BACKUP" ]; then
        aws s3 cp "$CONFIG_BACKUP" "s3://$S3_BUCKET/backups/config/" >> "$LOG_FILE" 2>&1
    fi
fi

# =========================================================
# Limpeza de Backups Antigos
# =========================================================

log_message "Removendo backups com mais de $DAYS_TO_KEEP dias..."

# Remover backups de banco antigos
DELETED_COUNT=$(find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +$DAYS_TO_KEEP -delete -print | wc -l)
log_message "Backups de banco removidos: $DELETED_COUNT"

# Remover backups de config antigos
DELETED_CONFIG=$(find "$BACKUP_DIR" -name "config_*.tar.gz" -mtime +$DAYS_TO_KEEP -delete -print | wc -l)
log_message "Backups de arquivos removidos: $DELETED_CONFIG"

# =========================================================
# Estatísticas Finais
# =========================================================

log_message "=========================================="
log_message "Backup concluído com sucesso!"
log_message "=========================================="

# Contar total de backups
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "backup_*.sql.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log_message "Total de backups de banco: $TOTAL_BACKUPS"
log_message "Espaço total usado: $TOTAL_SIZE"
log_message ""

# Listar últimos 5 backups
log_message "Últimos 5 backups:"
ls -lht "$BACKUP_DIR"/backup_*.sql.gz | head -5 | awk '{print $9, "-", $5}' >> "$LOG_FILE"

log_message ""
log_message "=========================================="

exit 0
