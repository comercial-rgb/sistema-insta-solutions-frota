# 🚀 QUICK START - Deploy Produção
## Frota Insta Solutions

**Para deploy completo, veja:** `DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md`  
**Para checklist passo a passo, veja:** `CHECKLIST_DEPLOY_PRODUCAO.md`

---

## ⚡ RESUMO RÁPIDO

### 1. No Servidor (Primeira vez)

```bash
# Conectar ao servidor
ssh usuario@[IP_SERVIDOR]

# Instalar dependências
sudo apt update && sudo apt upgrade -y
sudo apt install -y git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libmysqlclient-dev nodejs npm nginx certbot \
  python3-certbot-nginx mysql-server

# Instalar Ruby 3.3.0 via rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.3.0
rbenv global 3.3.0
gem install bundler

# Criar banco de dados
sudo mysql -u root -p
CREATE DATABASE sistema_insta_solutions_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'instasolutions'@'localhost' IDENTIFIED BY 'SENHA_FORTE';
GRANT ALL PRIVILEGES ON sistema_insta_solutions_production.* TO 'instasolutions'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 2. Deploy da Aplicação

```bash
# Criar estrutura
sudo mkdir -p /var/www/frotainstasolutions
sudo chown -R $USER:$USER /var/www/frotainstasolutions

# Clonar
cd /var/www/frotainstasolutions
git clone [URL_REPO] production
cd production

# Configurar
cp config/application.yml.example config/application.yml
nano config/application.yml  # Editar com credenciais

# Instalar e preparar
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile
chmod -R 777 tmp log storage
```

### 3. Configurar Serviços

```bash
# Systemd (Puma)
sudo cp config/systemd/frotainstasolutions.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable frotainstasolutions
sudo systemctl start frotainstasolutions

# Nginx
sudo cp config/nginx/frotainstasolutions.conf /etc/nginx/sites-available/frotainstasolutions
sudo ln -s /etc/nginx/sites-available/frotainstasolutions /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# SSL
sudo certbot --nginx -d app.frotainstasolutions.com.br

# Backup
sudo cp scripts/backup-frotainstasolutions.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-frotainstasolutions.sh
sudo mkdir -p /backups/frotainstasolutions
```

### 4. Configurar DNS

No painel do provedor de domínio:
```
Tipo: A
Nome: app
Valor: [IP_DO_SERVIDOR]
TTL: 3600
```

### 5. Testar

```bash
# Abrir no navegador
https://app.frotainstasolutions.com.br

# Ver logs
tail -f /var/www/frotainstasolutions/production/log/production.log
```

---

## 🔄 ATUALIZAÇÕES FUTURAS

```bash
# Conectar ao servidor
ssh usuario@[IP_SERVIDOR]

# Ir para diretório
cd /var/www/frotainstasolutions/production

# Fazer backup
sudo /usr/local/bin/backup-frotainstasolutions.sh

# Baixar atualizações
git pull origin main

# Instalar dependências (se necessário)
bundle install --deployment

# Migrar banco (se necessário)
RAILS_ENV=production bundle exec rails db:migrate

# Recompilar assets (se necessário)
RAILS_ENV=production bundle exec rails assets:precompile

# Reiniciar
sudo systemctl restart frotainstasolutions

# Verificar
sudo systemctl status frotainstasolutions
tail -f log/production.log
```

---

## 📋 ARQUIVOS IMPORTANTES

### Configurações criadas:

1. **`DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md`**  
   Guia completo com todos os detalhes

2. **`CHECKLIST_DEPLOY_PRODUCAO.md`**  
   Checklist passo a passo para marcar

3. **`config/application.yml.example`**  
   Template de configuração (atualizado com novo domínio)

4. **`config/nginx/frotainstasolutions.conf`**  
   Configuração Nginx otimizada

5. **`config/puma/production.rb`**  
   Configuração Puma para produção

6. **`config/systemd/frotainstasolutions.service`**  
   Service do systemd

7. **`scripts/backup-frotainstasolutions.sh`**  
   Script de backup automático

---

## 🆘 COMANDOS ÚTEIS

```bash
# Status
sudo systemctl status frotainstasolutions nginx mysql

# Reiniciar
sudo systemctl restart frotainstasolutions

# Logs
tail -f /var/www/frotainstasolutions/production/log/production.log

# Backup
sudo /usr/local/bin/backup-frotainstasolutions.sh

# Console Rails
cd /var/www/frotainstasolutions/production
RAILS_ENV=production bundle exec rails console
```

---

## ✅ PRÓXIMOS PASSOS

1. ⚙️ Configure o servidor seguindo: `DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md`
2. ✓ Use o checklist: `CHECKLIST_DEPLOY_PRODUCAO.md`
3. 🌐 Configure DNS para apontar para o servidor
4. 🔒 Configure SSL com Let's Encrypt
5. 📊 Monitore por 24-48h após deploy
6. 🎉 Sistema em produção!

---

**Domínio:** https://app.frotainstasolutions.com.br

---
