#!/bin/bash
# =========================================================
# Deploy Script - Frota Insta Solutions
# =========================================================
# Uso: ./deploy.sh
# 
# Este script faz deploy seguro no servidor de produção.
# Executa: git pull → bundle → assets → restart Puma (zero-downtime)
# =========================================================

set -e  # Para na primeira falha

# ===================== CONFIGURAÇÃO =====================
SERVER_USER="ubuntu"
SERVER_HOST="3.226.131.200"
SSH_KEY="$HOME/.ssh/frotainstasolutions-keypair.pem"
APP_DIR="/var/www/frotainstasolutions/production"
PUMA_CONFIG="config/puma/production.rb"
BRANCH="main"
# ========================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

SSH_CMD="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $SSH_KEY $SERVER_USER@$SERVER_HOST"

# ===================== VALIDAÇÕES =======================
echo ""
echo "=========================================="
echo "  DEPLOY - Frota Insta Solutions"
echo "=========================================="
echo ""

# Verificar chave SSH
if [ ! -f "$SSH_KEY" ]; then
    log_error "Chave SSH não encontrada: $SSH_KEY"
    exit 1
fi

# Verificar conexão
log_info "Testando conexão SSH..."
if ! $SSH_CMD "echo 'ok'" > /dev/null 2>&1; then
    log_error "Não foi possível conectar ao servidor $SERVER_HOST"
    exit 1
fi
log_ok "Conexão SSH OK"

# ===================== DEPLOY ===========================

# 1. Git Pull
log_info "Atualizando código (git pull origin $BRANCH)..."
$SSH_CMD "
    cd $APP_DIR
    git fetch origin $BRANCH
    git reset --hard origin/$BRANCH
" 2>&1 | tail -3
log_ok "Código atualizado"

# 2. Bundle Install
log_info "Instalando dependências (bundle install)..."
$SSH_CMD "
    export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    bundle install --deployment --without development test 2>&1 | tail -3
"
log_ok "Dependências instaladas"

# 3. Migrations (se houver)
log_info "Verificando migrations..."
PENDING=$($SSH_CMD "
    export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    RAILS_ENV=production bundle exec rails db:migrate:status 2>/dev/null | grep -c 'down' || echo '0'
" 2>/dev/null)

if [ "$PENDING" != "0" ] && [ -n "$PENDING" ]; then
    log_warn "Executando $PENDING migration(s) pendente(s)..."
    $SSH_CMD "
        export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
        eval \"\$(rbenv init -)\"
        cd $APP_DIR
        RAILS_ENV=production bundle exec rails db:migrate
    "
    log_ok "Migrations executadas"
else
    log_ok "Nenhuma migration pendente"
fi

# 4. Precompile Assets
log_info "Compilando assets..."
$SSH_CMD "
    export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -3
"
log_ok "Assets compilados"

# 5. Clear Cache
log_info "Limpando cache..."
$SSH_CMD "
    export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    RAILS_ENV=production bundle exec rails tmp:cache:clear 2>/dev/null
"
log_ok "Cache limpo"

# 6. Restart Puma (ZERO DOWNTIME)
log_info "Reiniciando Puma..."
RESTART_RESULT=$($SSH_CMD "
    export PATH=\"\$HOME/.rbenv/bin:\$HOME/.rbenv/shims:/usr/local/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    cd $APP_DIR
    mkdir -p tmp/sockets tmp/pids log

    PUMA_PID_FILE='tmp/pids/puma.pid'
    PUMA_SOCK='tmp/sockets/puma.sock'

    # preload_app! está ativo: USR2 reinicia workers mas herdam código antigo do master.
    # Full restart garante que o master carregue o código novo.
    echo 'FULL_RESTART'

    # Matar master (graceful) e esperar
    if [ -f \"\$PUMA_PID_FILE\" ]; then
        OLD_PID=\$(cat \$PUMA_PID_FILE)
        if kill -0 \$OLD_PID 2>/dev/null; then
            kill -TERM \$OLD_PID 2>/dev/null || true
            sleep 6
            kill -9 \$OLD_PID 2>/dev/null || true
        fi
    fi

    # Matar qualquer processo puma residual do app
    pkill -f 'puma.*frotainstasolutions' 2>/dev/null || true
    pkill -f 'puma.*tcp.*3000.*production' 2>/dev/null || true
    sleep 2

    # Limpar artefatos antigos
    rm -f \$PUMA_SOCK \$PUMA_PID_FILE tmp/pids/puma.state

    # Iniciar novo master com código novo
    RAILS_ENV=production nohup bundle exec puma -C $PUMA_CONFIG >> log/puma.log 2>&1 &
    disown

    # Aguardar socket ser criado (até 30s)
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        if [ -S \"\$PUMA_SOCK\" ]; then
            echo 'SUCCESS'
            exit 0
        fi
        sleep 2
    done

    echo 'TIMEOUT'
" 2>/dev/null)

if echo "$RESTART_RESULT" | grep -q "SUCCESS"; then
    log_ok "Puma reiniciado (restart completo — preload_app! recarregado)"
else
    log_error "Puma pode não ter iniciado corretamente. Verificar logs."
    log_warn "Comando para debug: ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST 'tail -50 $APP_DIR/log/puma_error.log'"
fi

# 7. Health Check
log_info "Verificando sistema..."
sleep 3
HTTP_CODE=$($SSH_CMD "curl -s -o /dev/null -w '%{http_code}' https://app.frotainstasolutions.com.br/login 2>/dev/null" 2>/dev/null)

echo ""
echo "=========================================="
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    log_ok "DEPLOY CONCLUÍDO COM SUCESSO!"
    log_ok "HTTP Status: $HTTP_CODE"
    log_ok "URL: https://app.frotainstasolutions.com.br"
else
    log_error "Health check retornou HTTP $HTTP_CODE"
    log_warn "Verificar: ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST 'tail -50 $APP_DIR/log/puma_error.log'"
fi
echo "=========================================="
echo ""
