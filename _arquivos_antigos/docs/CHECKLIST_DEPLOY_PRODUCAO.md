# ✅ CHECKLIST RÁPIDO - DEPLOY PRODUÇÃO
## app.frotainstasolutions.com.br

---

## 🔧 PRÉ-DEPLOY (No seu computador local)

- [ ] **Código testado e funcionando localmente**
- [ ] **Migrations criadas e testadas**
- [ ] **Assets compilam sem erros** (`rails assets:precompile`)
- [ ] **Testes passando** (`bundle exec rspec` ou `rails test`)
- [ ] **Backup do banco de produção atual feito** (se já existir sistema em produção)
- [ ] **Credenciais AWS S3 preparadas** (se usar para storage)
- [ ] **Credenciais SMTP preparadas** (para envio de emails)
- [ ] **Código enviado para repositório** (`git push`)

---

## 🖥️ SERVIDOR (Comandos no servidor de produção)

### 1. Configuração Inicial do Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y curl git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libmysqlclient-dev nodejs npm nginx certbot python3-certbot-nginx \
  mysql-server htop

# Instalar Ruby via rbenv (como usuário deploy)
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.3.0
rbenv global 3.3.0
gem install bundler
```

**Status:** [ ]

---

### 2. Configuração MySQL

```bash
# Configurar MySQL
sudo mysql_secure_installation

# Criar banco e usuário
sudo mysql -u root -p

CREATE DATABASE sistema_insta_solutions_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'instasolutions'@'localhost' IDENTIFIED BY 'SENHA_FORTE';
GRANT ALL PRIVILEGES ON sistema_insta_solutions_production.* TO 'instasolutions'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**Status:** [ ]

**Senha criada e salva:** [ ]

---

### 3. Deploy da Aplicação

```bash
# Criar estrutura
sudo mkdir -p /var/www/frotainstasolutions
sudo chown -R deploy:deploy /var/www/frotainstasolutions

# Clonar código
cd /var/www/frotainstasolutions
git clone [URL_DO_REPOSITORIO] production
cd production

# Configurar environment
cp config/application.yml.example config/application.yml
nano config/application.yml
```

**Editar application.yml:**
- [ ] DATABASE_USERNAME_PRODUCTION
- [ ] DATABASE_PASSWORD_PRODUCTION
- [ ] HOST: app.frotainstasolutions.com.br
- [ ] SECRET_KEY_BASE (gerar: `RAILS_ENV=production bundle exec rails secret`)
- [ ] AWS credentials (se usar S3)
- [ ] SMTP credentials

```bash
# Instalar dependências
bundle install --deployment --without development test
npm install --production

# Migrar banco (se necessário)
RAILS_ENV=production bundle exec rails db:migrate

# Compilar assets
RAILS_ENV=production bundle exec rails assets:precompile

# Ajustar permissões
chmod -R 755 /var/www/frotainstasolutions/production
chmod -R 777 tmp log storage
```

**Status:** [ ]

---

### 4. Configurar Puma (Systemd)

```bash
# Copiar arquivo de serviço
sudo cp /var/www/frotainstasolutions/production/config/systemd/frotainstasolutions.service \
  /etc/systemd/system/

# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar serviço
sudo systemctl enable frotainstasolutions

# Iniciar serviço
sudo systemctl start frotainstasolutions

# Verificar status
sudo systemctl status frotainstasolutions
```

**Status:** [ ]

**Puma rodando?** [ ]

---

### 5. Configurar Nginx

```bash
# Copiar configuração
sudo cp /var/www/frotainstasolutions/production/config/nginx/frotainstasolutions.conf \
  /etc/nginx/sites-available/frotainstasolutions

# Criar link simbólico
sudo ln -s /etc/nginx/sites-available/frotainstasolutions \
  /etc/nginx/sites-enabled/

# Remover configuração padrão (se existir)
sudo rm /etc/nginx/sites-enabled/default

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

**Status:** [ ]

**Nginx configurado?** [ ]

---

### 6. Configurar SSL (Let's Encrypt)

```bash
# Obter certificado SSL
sudo certbot --nginx -d app.frotainstasolutions.com.br

# Durante o processo:
# - Informar email
# - Aceitar termos
# - Escolher: Redirect HTTP to HTTPS (opção 2)

# Testar renovação automática
sudo certbot renew --dry-run
```

**Status:** [ ]

**SSL configurado?** [ ]

**HTTPS funcionando?** [ ]

---

### 7. Configurar Backup Automático

```bash
# Copiar script de backup
sudo cp /var/www/frotainstasolutions/production/scripts/backup-frotainstasolutions.sh \
  /usr/local/bin/

# Editar script com senha do banco
sudo nano /usr/local/bin/backup-frotainstasolutions.sh
# Alterar: DB_PASS="SUA_SENHA_AQUI"

# Tornar executável
sudo chmod +x /usr/local/bin/backup-frotainstasolutions.sh

# Criar diretório de backups
sudo mkdir -p /backups/frotainstasolutions
sudo chown -R deploy:deploy /backups/frotainstasolutions

# Testar backup manual
sudo /usr/local/bin/backup-frotainstasolutions.sh

# Configurar cron para backup diário às 2h
sudo crontab -e
# Adicionar linha:
# 0 2 * * * /usr/local/bin/backup-frotainstasolutions.sh >> /var/log/backup-frotainstasolutions.log 2>&1
```

**Status:** [ ]

**Backup testado?** [ ]

**Cron configurado?** [ ]

---

## 🌐 DNS

```bash
# Configurar registro DNS
# No painel do provedor de domínio:

Tipo: A
Nome: app
Valor: [IP_DO_SERVIDOR]
TTL: 3600
```

**Status:** [ ]

**DNS propagado?** [ ] (verificar com: `nslookup app.frotainstasolutions.com.br`)

---

## ✅ TESTES FINAIS

### Acessar Sistema

- [ ] **Abrir:** https://app.frotainstasolutions.com.br
- [ ] **Certificado SSL válido** (cadeado verde)
- [ ] **Página carrega corretamente**
- [ ] **Login funciona**
- [ ] **CRUD básico funciona** (criar, listar, editar, deletar)
- [ ] **Upload de arquivos funciona**
- [ ] **Emails sendo enviados** (testar recuperação de senha)
- [ ] **Sem erros no console do navegador** (F12)

### Verificar Logs

```bash
# Ver logs da aplicação
tail -f /var/www/frotainstasolutions/production/log/production.log

# Ver logs do Puma
tail -f /var/www/frotainstasolutions/production/log/puma_error.log

# Ver logs do Nginx
sudo tail -f /var/log/nginx/frotainstasolutions_error.log

# Ver logs do sistema
sudo journalctl -u frotainstasolutions -f
```

**Status:** [ ]

**Sem erros nos logs?** [ ]

---

## 📊 MONITORAMENTO (Primeiras 24h)

```bash
# Ver uso de recursos
htop

# Ver espaço em disco
df -h

# Ver status dos serviços
sudo systemctl status frotainstasolutions nginx mysql

# Ver conexões MySQL
sudo mysql -u root -p -e "SHOW PROCESSLIST;"
```

**Checklist 24h após deploy:**
- [ ] Sistema estável
- [ ] Sem quedas/erros
- [ ] Performance adequada (< 2s para páginas)
- [ ] Backup automático funcionou
- [ ] Logs sem erros críticos

---

## 🆘 COMANDOS ÚTEIS

### Reiniciar Serviços

```bash
# Reiniciar aplicação
sudo systemctl restart frotainstasolutions

# Reiniciar Nginx
sudo systemctl restart nginx

# Reiniciar MySQL
sudo systemctl restart mysql

# Reiniciar tudo
sudo systemctl restart frotainstasolutions nginx mysql
```

### Ver Logs em Tempo Real

```bash
# Aplicação
tail -f /var/www/frotainstasolutions/production/log/production.log

# Puma
tail -f /var/www/frotainstasolutions/production/log/puma_error.log

# Nginx
sudo tail -f /var/log/nginx/frotainstasolutions_error.log
```

### Fazer Backup Manual

```bash
sudo /usr/local/bin/backup-frotainstasolutions.sh
```

### Restaurar Backup

```bash
# Parar aplicação
sudo systemctl stop frotainstasolutions

# Restaurar
gunzip < /backups/frotainstasolutions/backup_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -u instasolutions -p sistema_insta_solutions_production

# Reiniciar
sudo systemctl start frotainstasolutions
```

---

## 📋 INFORMAÇÕES IMPORTANTES

**Servidor:**
- IP: _________________________
- SSH: _________________________
- Usuário: deploy

**Banco de Dados:**
- Host: localhost
- Porta: 3306
- Database: sistema_insta_solutions_production
- User: instasolutions
- Password: _________________________ (guardar em local seguro!)

**Domínio:**
- URL: https://app.frotainstasolutions.com.br
- SSL: Let's Encrypt (renovação automática)

**Backups:**
- Localização: /backups/frotainstasolutions
- Frequência: Diário às 2h
- Retenção: 30 dias

**Serviços:**
- Application: frotainstasolutions.service (systemd)
- Web Server: nginx
- Database: mysql

---

## 📞 SUPORTE

**Documentação completa:**
- Ver: `DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md`

**Em caso de problemas:**
1. Verificar logs
2. Reiniciar serviços
3. Verificar status com `systemctl status`
4. Consultar documentação completa

---

**✅ Deploy concluído com sucesso!**

**Data:** ___/___/______
**Responsável:** _________________________
**Versão:** _________________________

---
