# 🚀 GUIA DE DEPLOY - PRODUÇÃO
## Sistema Frota Insta Solutions

**Domínio:** app.frotainstasolutions.com.br  
**Data:** Janeiro 2026  
**Ambiente:** Produção

---

## 📋 ÍNDICE

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração do Servidor](#configuração-do-servidor)
3. [Configuração DNS](#configuração-dns)
4. [Instalação e Deploy](#instalação-e-deploy)
5. [SSL/HTTPS](#ssl-https)
6. [Backup e Rollback](#backup-e-rollback)
7. [Monitoramento](#monitoramento)

---

## 🔧 PRÉ-REQUISITOS

### ✅ Checklist Inicial

- [ ] Servidor Linux (Ubuntu 20.04/22.04 LTS recomendado)
- [ ] Acesso root/sudo ao servidor
- [ ] Domínio frotainstasolutions.com.br configurado
- [ ] Backup completo do sistema atual em produção
- [ ] Credenciais AWS (se usar S3 para arquivos)
- [ ] Conta de email SMTP configurada

### 📊 Recursos Mínimos do Servidor

**Para Produção:**
```
- CPU: 4 cores (mínimo 2 cores)
- RAM: 8 GB (mínimo 4 GB)
- Disco: 100 GB SSD
- Largura de banda: ilimitada ou mínimo 10 TB/mês
- Sistema: Ubuntu 22.04 LTS
```

---

## 🌐 CONFIGURAÇÃO DNS

### Passo 1: Configurar Registros DNS

Acesse o painel do seu provedor de domínio (Registro.br, Hostgator, etc.) e adicione:

```
Tipo: A
Nome: app
Valor: [IP_DO_SERVIDOR]
TTL: 3600 (1 hora)

Exemplo:
app.frotainstasolutions.com.br → 200.100.50.25
```

**Tempo de propagação:** 1-24 horas (geralmente < 2 horas)

### Verificar DNS

```bash
# Verificar se DNS está propagado
nslookup app.frotainstasolutions.com.br

# Ou usar dig
dig app.frotainstasolutions.com.br +short
```

---

## 🖥️ CONFIGURAÇÃO DO SERVIDOR

### Passo 1: Acessar o Servidor

```bash
# Conectar via SSH
ssh root@[IP_DO_SERVIDOR]

# Ou se tiver usuário específico
ssh usuario@[IP_DO_SERVIDOR]
```

### Passo 2: Atualizar Sistema

```bash
# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libmysqlclient-dev nodejs npm nginx certbot python3-certbot-nginx
```

### Passo 3: Instalar Ruby (via rbenv)

```bash
# Instalar rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Instalar ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Instalar Ruby 3.3.0
rbenv install 3.3.0
rbenv global 3.3.0

# Verificar instalação
ruby -v  # Deve mostrar: ruby 3.3.0
gem -v
```

### Passo 4: Instalar Bundler

```bash
gem install bundler
rbenv rehash
```

### Passo 5: Instalar MySQL Server

```bash
# Instalar MySQL
sudo apt install -y mysql-server

# Configurar MySQL
sudo mysql_secure_installation

# Criar banco de dados de produção
sudo mysql -u root -p

# No console MySQL:
CREATE DATABASE sistema_insta_solutions_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'instasolutions'@'localhost' IDENTIFIED BY 'SENHA_FORTE_AQUI';
GRANT ALL PRIVILEGES ON sistema_insta_solutions_production.* TO 'instasolutions'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**⚠️ IMPORTANTE:** Salve a senha criada! Você vai precisar dela.

### Passo 6: Configurar Usuário de Deploy

```bash
# Criar usuário para a aplicação
sudo adduser deploy
sudo usermod -aG sudo deploy

# Trocar para usuário deploy
su - deploy
```

---

## 📦 INSTALAÇÃO E DEPLOY

### Passo 1: Clonar Repositório

```bash
# Criar diretório da aplicação
sudo mkdir -p /var/www/frotainstasolutions
sudo chown -R deploy:deploy /var/www/frotainstasolutions

# Clonar repositório (ajuste a URL)
cd /var/www/frotainstasolutions
git clone https://github.com/SEU_USUARIO/sistema-insta-solutions.git production
cd production
```

**Ou se já tem o código localmente:**

```bash
# No seu computador local
scp -r /caminho/do/projeto deploy@[IP_SERVIDOR]:/var/www/frotainstasolutions/production
```

### Passo 2: Configurar Ambiente de Produção

```bash
cd /var/www/frotainstasolutions/production

# Copiar arquivo de configuração
cp config/application.yml.example config/application.yml

# Editar configurações
nano config/application.yml
```

**Configurar application.yml:**

```yaml
# ========================================
# PRODUÇÃO
# ========================================
DATABASE_DATABASE_PRODUCTION: "sistema_insta_solutions_production"
DATABASE_USERNAME_PRODUCTION: "instasolutions"
DATABASE_PASSWORD_PRODUCTION: "SENHA_QUE_VOCE_CRIOU"
DATABASE_HOST_PRODUCTION: "localhost"
DATABASE_PORT_PRODUCTION: "3306"

# Host da aplicação
HOST: "app.frotainstasolutions.com.br"

# AWS S3 (se usar para armazenar arquivos)
AWS_ACCESS_KEY_ID: "sua_aws_key"
AWS_SECRET_ACCESS_KEY: "sua_aws_secret"
AWS_REGION: "sa-east-1"
AWS_BUCKET: "frotainstasolutions-producao"

# SMTP (para envio de emails)
SMTP_ADDRESS: "smtp.gmail.com"
SMTP_PORT: "587"
SMTP_USERNAME: "seuemail@gmail.com"
SMTP_PASSWORD: "sua_senha_app"

# Secret Key Base (gerar novo)
SECRET_KEY_BASE: "GERAR_NOVO_ABAIXO"
```

**Gerar Secret Key Base:**

```bash
cd /var/www/frotainstasolutions/production
RAILS_ENV=production bundle exec rails secret
# Copie o resultado e cole no application.yml em SECRET_KEY_BASE
```

### Passo 3: Instalar Dependências

```bash
cd /var/www/frotainstasolutions/production

# Instalar gems
bundle install --deployment --without development test

# Instalar pacotes Node
npm install --production
# ou
yarn install --production
```

### Passo 4: Migrar Banco de Dados

**⚠️ CRÍTICO: Faça backup antes!**

```bash
# Se já tem dados no banco atual, faça backup primeiro
mysqldump -u root -p nome_banco_antigo > backup_antes_deploy_$(date +%Y%m%d).sql

# Restaurar no novo banco (se necessário)
mysql -u instasolutions -p sistema_insta_solutions_production < backup_antes_deploy_YYYYMMDD.sql

# Rodar migrations
cd /var/www/frotainstasolutions/production
RAILS_ENV=production bundle exec rails db:migrate

# Verificar status
RAILS_ENV=production bundle exec rails db:migrate:status
```

### Passo 5: Compilar Assets

```bash
cd /var/www/frotainstasolutions/production

# Precompilar assets
RAILS_ENV=production bundle exec rails assets:precompile

# Verificar se assets foram criados
ls -la public/assets/
```

### Passo 6: Configurar Permissões

```bash
cd /var/www/frotainstasolutions/production

# Criar diretórios necessários
mkdir -p tmp/pids tmp/sockets log

# Ajustar permissões
sudo chown -R deploy:deploy /var/www/frotainstasolutions/production
chmod -R 755 /var/www/frotainstasolutions/production
chmod -R 777 tmp log storage
```

---

## 🔒 SSL/HTTPS COM CERTBOT (Let's Encrypt)

### Passo 1: Instalar Certbot (já foi instalado anteriormente)

```bash
# Verificar se certbot está instalado
certbot --version
```

### Passo 2: Configurar Nginx ANTES de obter certificado

Crie o arquivo de configuração básico do Nginx:

```bash
sudo nano /etc/nginx/sites-available/frotainstasolutions
```

**Conteúdo inicial (sem SSL):**

```nginx
server {
    listen 80;
    server_name app.frotainstasolutions.com.br;

    root /var/www/frotainstasolutions/production/public;

    # Permite acesso ao diretório .well-known para validação SSL
    location ~ /.well-known {
        allow all;
    }

    location / {
        try_files $uri @app;
    }

    location @app {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    client_max_body_size 50M;
}
```

**Ativar site:**

```bash
# Criar link simbólico
sudo ln -s /etc/nginx/sites-available/frotainstasolutions /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

### Passo 3: Obter Certificado SSL

```bash
# Obter certificado (certbot vai modificar o arquivo nginx automaticamente)
sudo certbot --nginx -d app.frotainstasolutions.com.br

# Durante o processo:
# - Informe seu email
# - Aceite os termos
# - Escolha: Redirect HTTP to HTTPS (opção 2)
```

**O Certbot vai modificar automaticamente seu arquivo nginx para incluir SSL!**

### Passo 4: Renovação Automática

```bash
# Testar renovação
sudo certbot renew --dry-run

# Certbot já configura renovação automática via cron
# Verificar:
sudo systemctl status certbot.timer
```

---

## 🚀 INICIAR APLICAÇÃO

### Opção 1: Usando Puma (Recomendado para Produção)

**Criar arquivo de configuração Puma:**

```bash
nano /var/www/frotainstasolutions/production/config/puma.rb
```

**Conteúdo:**

```ruby
#!/usr/bin/env puma

directory '/var/www/frotainstasolutions/production'
rackup "/var/www/frotainstasolutions/production/config.ru"
environment 'production'

tag ''

pidfile "/var/www/frotainstasolutions/production/tmp/pids/puma.pid"
state_path "/var/www/frotainstasolutions/production/tmp/pids/puma.state"
stdout_redirect '/var/www/frotainstasolutions/production/log/puma_access.log', '/var/www/frotainstasolutions/production/log/puma_error.log', true

threads 0, 16
bind 'unix:///var/www/frotainstasolutions/production/tmp/sockets/puma.sock'
workers 2
preload_app!

on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = "/var/www/frotainstasolutions/production/Gemfile"
end
```

**Criar serviço systemd:**

```bash
sudo nano /etc/systemd/system/frotainstasolutions.service
```

**Conteúdo:**

```ini
[Unit]
Description=Frota Insta Solutions - Puma Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/frotainstasolutions/production
Environment=RAILS_ENV=production
Environment=RBENV_ROOT=/home/deploy/.rbenv
Environment=PATH=/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:/usr/local/bin:/usr/bin:/bin

ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C /var/www/frotainstasolutions/production/config/puma.rb
ExecReload=/bin/kill -USR1 $MAINPID

Restart=always
RestartSec=10

StandardOutput=append:/var/www/frotainstasolutions/production/log/puma_access.log
StandardError=append:/var/www/frotainstasolutions/production/log/puma_error.log

[Install]
WantedBy=multi-user.target
```

**Iniciar serviço:**

```bash
# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar inicialização automática
sudo systemctl enable frotainstasolutions

# Iniciar serviço
sudo systemctl start frotainstasolutions

# Verificar status
sudo systemctl status frotainstasolutions

# Ver logs em tempo real
sudo journalctl -u frotainstasolutions -f
```

**Atualizar configuração Nginx para usar socket Unix:**

```bash
sudo nano /etc/nginx/sites-available/frotainstasolutions
```

**Modificar a seção location @app:**

```nginx
location @app {
    proxy_pass http://unix:/var/www/frotainstasolutions/production/tmp/sockets/puma.sock;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;
}
```

```bash
# Testar e recarregar nginx
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔄 BACKUP E ROLLBACK

### Backup Automático de Banco de Dados

**Criar script de backup:**

```bash
sudo nano /usr/local/bin/backup-frotainstasolutions.sh
```

**Conteúdo:**

```bash
#!/bin/bash

# Configurações
BACKUP_DIR="/backups/frotainstasolutions"
DB_NAME="sistema_insta_solutions_production"
DB_USER="instasolutions"
DB_PASS="SUA_SENHA_AQUI"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

# Criar diretório se não existir
mkdir -p $BACKUP_DIR

# Fazer backup
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_FILE

# Comprimir
gzip $BACKUP_FILE

# Remover backups com mais de 30 dias
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup realizado: $BACKUP_FILE.gz"
```

**Tornar executável e agendar:**

```bash
sudo chmod +x /usr/local/bin/backup-frotainstasolutions.sh

# Adicionar ao crontab (backup diário às 2h da manhã)
sudo crontab -e

# Adicionar linha:
0 2 * * * /usr/local/bin/backup-frotainstasolutions.sh >> /var/log/backup-frotainstasolutions.log 2>&1
```

### Restaurar Backup

```bash
# Parar aplicação
sudo systemctl stop frotainstasolutions

# Restaurar banco
gunzip < /backups/frotainstasolutions/backup_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -u instasolutions -p sistema_insta_solutions_production

# Reiniciar aplicação
sudo systemctl start frotainstasolutions
```

---

## 📊 MONITORAMENTO

### Comandos Úteis

```bash
# Status da aplicação
sudo systemctl status frotainstasolutions

# Ver logs da aplicação
tail -f /var/www/frotainstasolutions/production/log/production.log

# Ver logs do Puma
tail -f /var/www/frotainstasolutions/production/log/puma_error.log

# Ver logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Reiniciar aplicação
sudo systemctl restart frotainstasolutions

# Reiniciar Nginx
sudo systemctl restart nginx

# Verificar uso de memória
free -h
htop

# Verificar espaço em disco
df -h

# Verificar portas em uso
sudo netstat -tulpn | grep LISTEN
```

### Monitorar Performance

```bash
# Instalar htop para monitoramento
sudo apt install -y htop

# Ver processos
htop

# Ver conexões ativas no MySQL
sudo mysql -u root -p -e "SHOW PROCESSLIST;"
```

---

## 🔄 ATUALIZAÇÕES FUTURAS

### Processo de Deploy de Atualizações

```bash
# 1. Conectar ao servidor
ssh deploy@[IP_SERVIDOR]

# 2. Ir para o diretório da aplicação
cd /var/www/frotainstasolutions/production

# 3. Fazer backup
mysqldump -u instasolutions -p sistema_insta_solutions_production > \
  /tmp/backup_pre_update_$(date +%Y%m%d).sql

# 4. Baixar últimas alterações
git pull origin main
# ou master, dependendo do nome da branch

# 5. Instalar dependências (se houver alterações)
bundle install --deployment
npm install --production

# 6. Rodar migrations
RAILS_ENV=production bundle exec rails db:migrate

# 7. Recompilar assets (se necessário)
RAILS_ENV=production bundle exec rails assets:precompile

# 8. Reiniciar aplicação
sudo systemctl restart frotainstasolutions

# 9. Verificar logs
tail -f log/production.log
```

---

## ✅ CHECKLIST FINAL

### Antes de Apontar DNS para Produção:

- [ ] Servidor configurado e acessível
- [ ] Ruby e dependências instaladas
- [ ] MySQL configurado com banco de produção
- [ ] Código da aplicação clonado e configurado
- [ ] `config/application.yml` configurado corretamente
- [ ] SECRET_KEY_BASE gerado e configurado
- [ ] Migrations executadas com sucesso
- [ ] Assets compilados
- [ ] Nginx configurado
- [ ] SSL configurado (Let's Encrypt)
- [ ] Puma/servidor iniciado como serviço
- [ ] Aplicação acessível via HTTPS
- [ ] Backup automático configurado
- [ ] Testar login no sistema
- [ ] Testar funcionalidades principais
- [ ] Verificar emails sendo enviados

### Após Deploy:

- [ ] Monitorar logs por 24-48h
- [ ] Verificar performance (tempo de resposta)
- [ ] Confirmar que backups estão funcionando
- [ ] Documentar credenciais em local seguro
- [ ] Treinar equipe no novo ambiente

---

## 🆘 TROUBLESHOOTING

### Erro: "Could not find gem..."

```bash
cd /var/www/frotainstasolutions/production
bundle install
sudo systemctl restart frotainstasolutions
```

### Erro: "Permission denied"

```bash
sudo chown -R deploy:deploy /var/www/frotainstasolutions/production
chmod -R 755 /var/www/frotainstasolutions/production
chmod -R 777 tmp log storage
```

### Erro: "Database connection failed"

```bash
# Verificar se MySQL está rodando
sudo systemctl status mysql

# Testar conexão
mysql -u instasolutions -p sistema_insta_solutions_production

# Verificar config/application.yml
nano config/application.yml
```

### Aplicação não carrega (502 Bad Gateway)

```bash
# Verificar se Puma está rodando
sudo systemctl status frotainstasolutions

# Ver logs
tail -f /var/www/frotainstasolutions/production/log/puma_error.log

# Reiniciar
sudo systemctl restart frotainstasolutions
```

### SSL não funciona

```bash
# Verificar certificado
sudo certbot certificates

# Renovar manualmente
sudo certbot renew

# Verificar configuração nginx
sudo nginx -t
```

---

## 📞 SUPORTE

### Logs Importantes

```
/var/www/frotainstasolutions/production/log/production.log
/var/www/frotainstasolutions/production/log/puma_error.log
/var/log/nginx/error.log
```

### Comandos Rápidos

```bash
# Restart completo
sudo systemctl restart frotainstasolutions nginx mysql

# Ver últimas 100 linhas de log
tail -100 /var/www/frotainstasolutions/production/log/production.log

# Ver status de todos os serviços
sudo systemctl status frotainstasolutions nginx mysql
```

---

**🎉 Parabéns! Seu sistema está em produção!**

**URL:** https://app.frotainstasolutions.com.br

---

*Última atualização: Janeiro 2026*
