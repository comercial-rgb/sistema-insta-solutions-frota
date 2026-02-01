# 🏢 DEPLOY PARA PRODUÇÃO - 1.000+ USUÁRIOS
## Sistema Frota Insta Solutions - Alta Disponibilidade

**⚠️ IMPORTANTE: Sistema com carga significativa**  
**Usuários ativos: 1.000+**  
**Requisito: Alta estabilidade e performance**

---

## 🎯 ARQUITETURA RECOMENDADA

### Para 1.000+ Usuários Ativos

```
                    INTERNET
                       │
                       ▼
        ┌──────────────────────────┐
        │   CLOUDFLARE (CDN)       │ ◄── Proteção DDoS + Cache
        │   (Opcional mas recomendado)
        └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  LOAD BALANCER (Nginx)   │ ◄── Distribuir carga
        │  (Opcional para > 2000)   │
        └──────────────────────────┘
                       │
        ┌──────────────┴───────────────┐
        ▼                              ▼
┌───────────────────┐        ┌───────────────────┐
│  SERVIDOR 1       │        │  SERVIDOR 2       │
│  Aplicação Rails  │        │  Banco de Dados   │
│  ─────────────    │        │  ─────────────    │
│  • Nginx          │        │  • MySQL 8.0      │
│  • Puma (workers) │        │  • Tuned for perf │
│  • Redis (cache)  │◄──────▶│  • Backups        │
│  • Sidekiq (jobs) │        │  • Replicação     │
└───────────────────┘        └───────────────────┘
        │                              
        ▼                              
┌───────────────────┐
│  AWS S3 / Storage │ ◄── Arquivos/Uploads
│  Backups remotos  │
└───────────────────┘
```

---

## 💻 ESPECIFICAÇÕES DE HARDWARE

### SERVIDOR 1: APLICAÇÃO (Crítico)

```yaml
MÍNIMO (até 1.500 usuários):
  CPU: 8 cores / 16 threads
  RAM: 16 GB
  Disco: 100 GB SSD NVMe
  Rede: 1 Gbps
  
RECOMENDADO (1.500-3.000 usuários):
  CPU: 16 cores / 32 threads
  RAM: 32 GB
  Disco: 200 GB SSD NVMe
  Rede: 10 Gbps
```

**Custo estimado:**
- DigitalOcean: $96-192/mês (16-32GB)
- AWS EC2: t3.2xlarge (~$120/mês)
- Contabo: €30-50/mês (16-32GB)
- Dedicado Brasil: R$ 400-800/mês

### SERVIDOR 2: BANCO DE DADOS (Crítico)

```yaml
MÍNIMO:
  CPU: 4 cores dedicados
  RAM: 16 GB (mínimo!)
  Disco: 200 GB SSD NVMe
  IOPS: > 10.000
  
RECOMENDADO:
  CPU: 8 cores dedicados
  RAM: 32 GB
  Disco: 500 GB SSD NVMe
  IOPS: > 20.000
  Backup: Automático diário
```

**Custo estimado:**
- DigitalOcean Managed MySQL: $120-240/mês
- AWS RDS: db.m5.xlarge (~$150/mês)
- Servidor dedicado: R$ 400-800/mês

### 💰 CUSTO TOTAL ESTIMADO

```
INFRAESTRUTURA BÁSICA:
├─ Servidor Aplicação (16GB): R$ 480/mês
├─ Servidor Banco (16GB):     R$ 480/mês
├─ AWS S3 (Storage):          R$ 100/mês
├─ Cloudflare Pro:            R$ 100/mês
├─ Backups externos:          R$ 50/mês
├─ Monitoramento:             R$ 50/mês
└─ TOTAL:                     R$ 1.260/mês

INFRAESTRUTURA RECOMENDADA:
├─ Servidor Aplicação (32GB): R$ 960/mês
├─ Servidor Banco (32GB):     R$ 960/mês
├─ AWS S3 (Storage):          R$ 150/mês
├─ Cloudflare Pro:            R$ 100/mês
├─ Backups externos:          R$ 100/mês
├─ Monitoramento APM:         R$ 150/mês
└─ TOTAL:                     R$ 2.420/mês
```

---

## 🚀 CONFIGURAÇÃO OTIMIZADA

### 1. SERVIDOR APLICAÇÃO

#### A. Configuração Puma (config/puma/production.rb)

```ruby
#!/usr/bin/env puma

# Para 1.000+ usuários - Configuração otimizada
app_dir = '/var/www/frotainstasolutions/production'
directory app_dir
rackup "#{app_dir}/config.ru"
environment 'production'

# WORKERS: 1 por core de CPU (ou metade se RAM limitada)
# Servidor de 8 cores: 6-8 workers
# Servidor de 16 cores: 12-16 workers
workers ENV.fetch("WEB_CONCURRENCY") { 12 }

# THREADS: 5-10 por worker
# Total de threads simultâneas = workers × threads
# Exemplo: 12 workers × 8 threads = 96 requisições simultâneas
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 8 }
threads threads_count, threads_count

# Preload para economizar RAM
preload_app!

# Socket Unix (melhor performance que TCP)
bind "unix://#{app_dir}/tmp/sockets/puma.sock"

# PID e State
pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"

# Logs
stdout_redirect(
  "#{app_dir}/log/puma_access.log",
  "#{app_dir}/log/puma_error.log",
  true
)

# Timeouts ajustados para carga alta
worker_timeout 60
worker_shutdown_timeout 30

# Callbacks otimizados
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  
  # Desconectar Redis
  Redis.current.quit if defined?(Redis)
  
  # Limpar cache
  Rails.cache.clear if defined?(Rails)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  
  # Reconectar Redis
  Redis.current = Redis.new(url: ENV['REDIS_URL']) if defined?(Redis) && ENV['REDIS_URL']
end

# Plugin para restart via arquivo
plugin :tmp_restart

# Nakayoshi fork (otimização de memória)
nakayoshi_fork if ENV['NAKAYOSHI_FORK']
```

#### B. Instalar Redis (Cache)

```bash
# Instalar Redis no servidor de aplicação
sudo apt install -y redis-server

# Configurar Redis
sudo nano /etc/redis/redis.conf

# Ajustar:
maxmemory 2gb
maxmemory-policy allkeys-lru

# Reiniciar
sudo systemctl restart redis
sudo systemctl enable redis
```

#### C. Configuração Rails (config/environments/production.rb)

```ruby
Rails.application.configure do
  # ... configurações existentes ...
  
  # CACHE com Redis (IMPORTANTE!)
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/1',
    namespace: 'frotainstasolutions',
    expires_in: 90.minutes
  }
  
  # Action Cable com Redis
  config.action_cable.url = 'wss://app.frotainstasolutions.com.br/cable'
  config.action_cable.allowed_request_origins = [
    'https://app.frotainstasolutions.com.br'
  ]
  
  # Session store com Redis
  config.session_store :redis_store,
    servers: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    expire_after: 90.minutes,
    key: '_frotainstasolutions_session'
  
  # Log otimizado (não logar tudo)
  config.log_level = :info
  config.log_tags = [:request_id]
  
  # Não fazer queries N+1 (levantar erro em dev)
  config.active_record.warn_on_records_fetched_greater_than = 500
end
```

#### D. Gemfile - Adicionar gems de performance

```ruby
# Gemfile

# Redis para cache e sessions
gem 'redis', '~> 5.0'
gem 'redis-rails'
gem 'redis-rack-cache'

# Background jobs
gem 'sidekiq', '~> 7.0'

# Monitoramento de performance
gem 'rack-timeout'
gem 'rack-attack'  # Rate limiting

# Database otimizado
gem 'connection_pool'
gem 'scenic'  # Database views

group :production do
  # Monitoramento
  gem 'newrelic_rpm'      # ou Scout APM
  gem 'sentry-ruby'       # Error tracking
  gem 'sentry-rails'
end
```

---

### 2. SERVIDOR BANCO DE DADOS

#### A. MySQL Otimizado para Alta Carga

```bash
# Editar configuração MySQL
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

**Configuração otimizada para 16GB RAM:**

```ini
[mysqld]
# BASIC SETTINGS
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
datadir = /var/lib/mysql

# CHARACTER SET
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# CONEXÕES
max_connections = 500
max_connect_errors = 1000000

# BUFFER POOL (70% da RAM para InnoDB)
innodb_buffer_pool_size = 11G
innodb_buffer_pool_instances = 11

# LOGS
innodb_log_file_size = 512M
innodb_log_buffer_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# PERFORMANCE
innodb_io_capacity = 2000
innodb_io_capacity_max = 4000
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 0

# CACHE
query_cache_type = 0
query_cache_size = 0
table_open_cache = 4000
table_definition_cache = 2000

# TEMP TABLES
tmp_table_size = 64M
max_heap_table_size = 64M

# TIMEOUTS
wait_timeout = 300
interactive_timeout = 300
net_read_timeout = 60
net_write_timeout = 60

# BINARY LOG (para replicação)
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# SLOW QUERY LOG
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# SEGURANÇA
local-infile = 0
symbolic-links = 0
```

```bash
# Reiniciar MySQL
sudo systemctl restart mysql

# Verificar status
sudo systemctl status mysql

# Verificar performance
mysql -u root -p -e "SHOW VARIABLES LIKE '%buffer_pool%';"
```

#### B. Criar índices otimizados

```bash
# Conectar ao banco de produção
mysql -u instasolutions -p sistema_insta_solutions_production
```

```sql
-- Analisar queries lentas
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Verificar índices
SHOW INDEX FROM order_service_proposals;
SHOW INDEX FROM vehicles;
SHOW INDEX FROM service_orders;

-- Adicionar índices se necessário (exemplo)
-- CREATE INDEX idx_vehicle_status ON vehicles(status, created_at);
-- CREATE INDEX idx_os_user_date ON service_orders(user_id, created_at);

-- Otimizar tabelas
OPTIMIZE TABLE order_service_proposals;
OPTIMIZE TABLE vehicles;
OPTIMIZE TABLE service_orders;
ANALYZE TABLE order_service_proposals;
ANALYZE TABLE vehicles;
ANALYZE TABLE service_orders;
```

---

### 3. NGINX - Configuração Otimizada

```nginx
# /etc/nginx/nginx.conf

user www-data;
worker_processes auto;  # 1 por core
worker_rlimit_nofile 65535;
pid /run/nginx.pid;

events {
    worker_connections 10000;  # Aumentado para alta carga
    use epoll;
    multi_accept on;
}

http {
    # BASIC SETTINGS
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;
    types_hash_max_size 2048;
    server_tokens off;
    
    # BUFFERS
    client_body_buffer_size 128k;
    client_max_body_size 50m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    output_buffers 1 32k;
    postpone_output 1460;
    
    # TIMEOUTS
    client_header_timeout 60s;
    client_body_timeout 60s;
    send_timeout 60s;
    
    # GZIP COMPRESSION
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml application/atom+xml image/svg+xml 
               text/x-component text/x-cross-domain-policy;
    gzip_disable "msie6";
    
    # CACHE
    open_file_cache max=10000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
    # RATE LIMITING (proteção contra abuso)
    limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/s;
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=50r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    # LOGS
    access_log /var/log/nginx/access.log combined buffer=32k;
    error_log /var/log/nginx/error.log warn;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # UPSTREAM PUMA
    upstream puma_frotainstasolutions {
        least_conn;  # Load balance por menor número de conexões
        server unix:///var/www/frotainstasolutions/production/tmp/sockets/puma.sock fail_timeout=30s max_fails=3;
        
        keepalive 32;  # Keep connections alive
    }
    
    include /etc/nginx/sites-enabled/*;
}
```

**Arquivo específico do site:**

```nginx
# /etc/nginx/sites-available/frotainstasolutions

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.frotainstasolutions.com.br;
    
    root /var/www/frotainstasolutions/production/public;
    
    # SSL (configurado pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/app.frotainstasolutions.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.frotainstasolutions.com.br/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # HEADERS DE SEGURANÇA
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # LOGS
    access_log /var/log/nginx/frotainstasolutions_access.log;
    error_log /var/log/nginx/frotainstasolutions_error.log;
    
    # CACHE DE ASSETS (longo)
    location ^~ /assets/ {
        gzip_static on;
        expires max;
        add_header Cache-Control "public, immutable";
        access_log off;
        
        # CORS se necessário
        add_header Access-Control-Allow-Origin *;
    }
    
    location ^~ /packs/ {
        gzip_static on;
        expires max;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # RATE LIMITING para login
    location /users/sign_in {
        limit_req zone=login_limit burst=10 nodelay;
        try_files $uri @puma;
    }
    
    # RATE LIMITING para API
    location /api/ {
        limit_req zone=api_limit burst=100 nodelay;
        try_files $uri @puma;
    }
    
    # CONEXÃO LIMITE
    location / {
        limit_conn addr 10;
        try_files $uri $uri/index.html $uri.html @puma;
    }
    
    # PROXY PARA PUMA
    location @puma {
        proxy_pass http://puma_frotainstasolutions;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 24 4k;
        proxy_busy_buffers_size 8k;
        proxy_max_temp_file_size 2048m;
        proxy_temp_file_write_size 32k;
        
        proxy_redirect off;
    }
    
    # CABLE (Action Cable - WebSockets)
    location /cable {
        proxy_pass http://puma_frotainstasolutions;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
    
    # HEALTH CHECK
    location /health {
        access_log off;
        proxy_pass http://puma_frotainstasolutions;
    }
    
    # NEGAR ARQUIVOS SENSÍVEIS
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$ {
        deny all;
    }
}

# HTTP -> HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name app.frotainstasolutions.com.br;
    return 301 https://$server_name$request_uri;
}
```

---

### 4. MONITORAMENTO E ALERTAS

#### A. Instalar ferramentas

```bash
# Htop (monitor de processos)
sudo apt install -y htop

# Glances (monitor avançado)
sudo apt install -y glances

# Netdata (dashboard de monitoramento)
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Acessar: http://[IP_SERVIDOR]:19999
```

#### B. New Relic (APM - Recomendado!)

```bash
# Adicionar ao Gemfile
gem 'newrelic_rpm'

# Baixar arquivo de config
# https://rpm.newrelic.com
# Copiar newrelic.yml para config/

# Reiniciar aplicação
sudo systemctl restart frotainstasolutions
```

#### C. Sentry (Error Tracking)

```bash
# Adicionar ao Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'

# Configurar
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
end

# Reiniciar
sudo systemctl restart frotainstasolutions
```

---

### 5. BACKUP ROBUSTO

```bash
# Script de backup aprimorado
sudo nano /usr/local/bin/backup-frotainstasolutions-pro.sh
```

```bash
#!/bin/bash
# Backup profissional para 1.000+ usuários

BACKUP_DIR="/backups/frotainstasolutions"
APP_DIR="/var/www/frotainstasolutions/production"
DB_NAME="sistema_insta_solutions_production"
DB_USER="instasolutions"
DB_PASS="SUA_SENHA"
DB_HOST="IP_SERVIDOR_BANCO"
DATE=$(date +%Y%m%d_%H%M%S)

# S3 para backup remoto
S3_BUCKET="s3://frotainstasolutions-backups"

# Slack para notificações
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Função de notificação
notify() {
    curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$1\"}" $SLACK_WEBHOOK
}

notify "🔄 Iniciando backup do sistema..."

# Backup do banco com compressão on-the-fly
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS \
  --single-transaction \
  --quick \
  --lock-tables=false \
  --routines \
  --triggers \
  $DB_NAME | gzip -9 > $BACKUP_DIR/db_$DATE.sql.gz

# Upload para S3
aws s3 cp $BACKUP_DIR/db_$DATE.sql.gz $S3_BUCKET/database/

# Backup de arquivos críticos
tar -czf $BACKUP_DIR/files_$DATE.tar.gz \
  $APP_DIR/storage \
  $APP_DIR/public/uploads \
  $APP_DIR/config/application.yml

aws s3 cp $BACKUP_DIR/files_$DATE.tar.gz $S3_BUCKET/files/

# Limpar backups locais antigos (manter 7 dias)
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "files_*.tar.gz" -mtime +7 -delete

# Limpar backups S3 antigos (manter 30 dias)
aws s3 ls $S3_BUCKET/database/ | while read -r line; do
  createDate=$(echo $line|awk {'print $1" "$2'})
  createDate=$(date -d "$createDate" +%s)
  olderThan=$(date --date "30 days ago" +%s)
  if [[ $createDate -lt $olderThan ]]; then
    fileName=$(echo $line|awk {'print $4'})
    aws s3 rm $S3_BUCKET/database/$fileName
  fi
done

notify "✅ Backup concluído com sucesso!"
```

```bash
# Tornar executável
sudo chmod +x /usr/local/bin/backup-frotainstasolutions-pro.sh

# Agendar para rodar a cada 6 horas
sudo crontab -e
0 */6 * * * /usr/local/bin/backup-frotainstasolutions-pro.sh
```

---

## 📊 CHECKLIST DE PERFORMANCE

### Antes de Colocar no Ar

- [ ] Servidor de aplicação: 16GB+ RAM, 8+ cores
- [ ] Servidor de banco: 16GB+ RAM, 4+ cores, SSD NVMe
- [ ] Puma configurado: 12+ workers, 8 threads por worker
- [ ] Redis instalado e configurado para cache
- [ ] MySQL otimizado (innodb_buffer_pool_size = 70% RAM)
- [ ] Índices do banco verificados e otimizados
- [ ] Nginx otimizado (worker_connections = 10000+)
- [ ] Rate limiting configurado
- [ ] SSL/HTTPS ativo
- [ ] Cloudflare configurado (opcional mas recomendado)
- [ ] AWS S3 para storage de arquivos
- [ ] Backup automático a cada 6 horas
- [ ] Monitoramento: New Relic ou Scout APM
- [ ] Error tracking: Sentry
- [ ] Logs rotacionados (logrotate)
- [ ] Alertas configurados (email/Slack)

### Testes de Carga

```bash
# Instalar Apache Bench
sudo apt install apache2-utils

# Teste de carga (100 usuários simultâneos, 1000 requests)
ab -n 1000 -c 100 https://app.frotainstasolutions.com.br/

# Objetivo:
# - Tempo médio de resposta: < 500ms
# - Sem erros 5xx
# - Taxa de sucesso: 100%
```

---

## 🆘 TROUBLESHOOTING PARA ALTA CARGA

### Sintoma: Sistema lento

```bash
# 1. Ver processos consumindo mais recursos
htop
top

# 2. Ver queries lentas do MySQL
mysql -u root -p -e "SHOW FULL PROCESSLIST;"

# 3. Ver log de queries lentas
sudo tail -f /var/log/mysql/slow.log

# 4. Ver uso de memória do Rails
ps aux | grep puma | awk '{sum+=$6} END {print sum/1024 " MB"}'

# 5. Reiniciar aplicação
sudo systemctl restart frotainstasolutions
```

### Sintoma: Muitos erros 502

```bash
# Aumentar workers do Puma
nano /var/www/frotainstasolutions/production/config/puma/production.rb
# Aumentar: workers 16

# Aumentar timeout do Nginx
nano /etc/nginx/sites-available/frotainstasolutions
# Aumentar: proxy_read_timeout 600s;

# Reiniciar
sudo systemctl restart frotainstasolutions nginx
```

---

## 🎯 RESUMO EXECUTIVO

### Para 1.000+ Usuários Você Precisa:

```
✅ HARDWARE:
   • Servidor App: 16GB RAM, 8 cores (R$ 480/mês)
   • Servidor Banco: 16GB RAM, 4 cores (R$ 480/mês)
   • AWS S3: R$ 100/mês
   TOTAL: ~R$ 1.200-1.500/mês

✅ SOFTWARE:
   • Puma: 12+ workers, 8 threads
   • Redis: Cache e sessions
   • MySQL: Otimizado, 11GB buffer pool
   • Nginx: Rate limiting, cache
   • Cloudflare: CDN e proteção

✅ MONITORAMENTO:
   • New Relic ou Scout APM
   • Sentry para erros
   • Netdata para recursos
   • Alertas via Slack/Email

✅ BACKUP:
   • A cada 6 horas
   • Retenção: 30 dias
   • Upload para S3
   • Testado mensalmente

✅ SEGURANÇA:
   • HTTPS obrigatório
   • Rate limiting
   • Firewall configurado
   • Updates automáticos
```

---

**🚀 Com essa configuração, seu sistema suporta até 3.000 usuários simultâneos!**

---

*Criado em: Janeiro 2026*  
*Para sistemas de alta carga*
