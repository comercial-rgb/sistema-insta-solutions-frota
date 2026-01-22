# 🚀 Guia de Deployment - Sistema Insta Solutions

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração AWS](#configuração-aws)
3. [Configuração GitHub](#configuração-github)
4. [Deploy Staging](#deploy-staging)
5. [Deploy Production](#deploy-production)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Contas necessárias:
- ✅ Conta AWS (com cartão de crédito cadastrado)
- ✅ Acesso GitHub ao repositório
- ✅ Arquivo dump de produção (.sql)

### Custos estimados AWS (mensais):
- **Staging**: ~$50-70/mês
  - EC2 t3.small: ~$15
  - RDS db.t3.micro: ~$15
  - S3: ~$5
  - Outros: ~$10-20
  
- **Production**: ~$150-200/mês
  - EC2 t3.medium: ~$30
  - RDS db.t3.small: ~$30
  - S3: ~$10
  - CloudFront: ~$20
  - Load Balancer: ~$20
  - Outros: ~$40-60

---

## ☁️ Configuração AWS

### Passo 1: Criar usuário IAM

1. Acesse [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Clique em **Users** → **Add users**
3. Nome do usuário: `github-actions-deployer`
4. Marque: **Access key - Programmatic access**
5. Clique em **Next: Permissions**

### Passo 2: Configurar permissões

Anexe as seguintes políticas ao usuário:

```
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonS3FullAccess
- AmazonVPCFullAccess
- IAMFullAccess (ou IAMReadOnlyAccess)
- CloudFrontFullAccess
```

**⚠️ IMPORTANTE**: Salve as credenciais:
```
AWS_ACCESS_KEY_ID: AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Passo 3: Criar Key Pair SSH

1. Acesse [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Vá em **Network & Security** → **Key Pairs**
3. Clique em **Create key pair**
4. Nome: `instasolutions-deploy-key`
5. Type: **RSA**
6. Format: **pem**
7. Clique em **Create key pair**
8. **Salve o arquivo .pem** em local seguro!

### Passo 4: Criar banco RDS (Staging)

1. Acesse [RDS Console](https://console.aws.amazon.com/rds/)
2. Clique em **Create database**
3. Configure:

```yaml
Engine: MySQL 8.0
Template: Free tier (ou Dev/Test para staging)
DB instance identifier: instasolutions-staging-db
Master username: admin
Master password: [CRIE UMA SENHA FORTE - SALVE!]
DB instance class: db.t3.micro
Storage: 20 GB SSD
VPC: Default VPC
Public access: Yes (para facilitar acesso inicial)
Database name: sistema_insta_solutions_staging
```

4. Clique em **Create database**
5. Aguarde ~10 minutos até status ficar **Available**
6. Anote o **Endpoint**: `instasolutions-staging-db.xxxxx.us-east-1.rds.amazonaws.com`

### Passo 5: Criar bucket S3

```bash
# Staging
aws s3 mb s3://instasolutions-staging-uploads --region us-east-1

# Production
aws s3 mb s3://instasolutions-production-uploads --region us-east-1
```

**Configure permissões públicas de leitura** (para imagens/uploads):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::instasolutions-staging-uploads/*"
    }
  ]
}
```

---

## 🔐 Configuração GitHub

### Passo 1: Adicionar Secrets

1. Acesse seu repositório no GitHub
2. Vá em **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**

### Secrets necessários:

#### AWS Credentials (Geral)
```
AWS_ACCESS_KEY_ID
Valor: AKIAXXXXXXXXXXXXXXXX

AWS_SECRET_ACCESS_KEY
Valor: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

AWS_REGION
Valor: us-east-1

EC2_SSH_KEY
Valor: [Conteúdo completo do arquivo .pem gerado]
```

#### Staging Environment
```
STAGING_EC2_HOST
Valor: [IP público da EC2 staging - criar depois]

STAGING_DB_HOST
Valor: instasolutions-staging-db.xxxxx.us-east-1.rds.amazonaws.com

STAGING_DB_NAME
Valor: sistema_insta_solutions_staging

STAGING_DB_USERNAME
Valor: admin

STAGING_DB_PASSWORD
Valor: [senha do RDS staging]

STAGING_SECRET_KEY_BASE
Valor: [gerar com: rails secret]

STAGING_S3_BUCKET
Valor: instasolutions-staging-uploads
```

#### Production Environment
```
PRODUCTION_EC2_HOST
Valor: [IP público da EC2 production - criar depois]

PRODUCTION_DB_HOST
Valor: [endpoint RDS production]

PRODUCTION_DB_NAME
Valor: sistema_insta_solutions_production

PRODUCTION_DB_USERNAME
Valor: admin

PRODUCTION_DB_PASSWORD
Valor: [senha do RDS production]

PRODUCTION_SECRET_KEY_BASE
Valor: [gerar com: rails secret]

PRODUCTION_S3_BUCKET
Valor: instasolutions-production-uploads
```

### Passo 2: Gerar SECRET_KEY_BASE

Execute localmente:

```bash
# Staging
bundle exec rails secret
# Copie o resultado e adicione como STAGING_SECRET_KEY_BASE

# Production
bundle exec rails secret
# Copie o resultado e adicione como PRODUCTION_SECRET_KEY_BASE
```

---

## 🧪 Deploy Staging

### Passo 1: Criar instância EC2 Staging

1. Acesse [EC2 Console](https://console.aws.amazon.com/ec2/)
2. Clique em **Launch Instance**
3. Configure:

```yaml
Name: instasolutions-staging
AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
Instance type: t3.small
Key pair: instasolutions-deploy-key
Network settings:
  - Auto-assign public IP: Enable
  - Security Group: Create new
    - SSH (22): My IP
    - HTTP (80): Anywhere (0.0.0.0/0)
    - HTTPS (443): Anywhere (0.0.0.0/0)
    - Custom TCP (3000): Anywhere (para Rails)
Storage: 20 GB gp3
```

4. Clique em **Launch instance**
5. Aguarde até status **Running**
6. **Anote o IP público**: `54.XXX.XXX.XXX`
7. Adicione como secret `STAGING_EC2_HOST` no GitHub

### Passo 2: Configurar EC2 manualmente (primeira vez)

Conecte via SSH:

```bash
ssh -i instasolutions-deploy-key.pem ubuntu@54.XXX.XXX.XXX
```

Execute os comandos de setup:

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev libreadline-dev \
  libncurses5-dev libffi-dev libgdbm-dev mysql-client imagemagick \
  libmagickwand-dev nodejs npm

# Instalar rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Instalar Ruby 3.2.2
rbenv install 3.2.2
rbenv global 3.2.2

# Instalar Bundler
gem install bundler

# Configurar deploy user
sudo adduser deploy
sudo usermod -aG sudo deploy

# Criar diretórios da aplicação
sudo mkdir -p /var/www/instasolutions
sudo chown deploy:deploy /var/www/instasolutions
```

### Passo 3: Importar banco de dados staging

No seu computador local:

```bash
# 1. Upload do dump para EC2
scp -i instasolutions-deploy-key.pem prod_instasolutions_22-01-26_13-21-49.sql ubuntu@54.XXX.XXX.XXX:/tmp/

# 2. Conectar na EC2 e importar
ssh -i instasolutions-deploy-key.pem ubuntu@54.XXX.XXX.XXX

# 3. Importar para RDS
mysql -h instasolutions-staging-db.xxxxx.us-east-1.rds.amazonaws.com \
      -u admin -p sistema_insta_solutions_staging < /tmp/prod_instasolutions_22-01-26_13-21-49.sql

# 4. Aplicar correções (após primeiro deploy)
cd /var/www/instasolutions/current
RAILS_ENV=staging bundle exec rails runner scripts/sync_status_ids.rb
RAILS_ENV=staging bundle exec rails runner scripts/fix_users_encoding.rb
RAILS_ENV=staging bundle exec rails runner scripts/add_os_complement_columns.rb
```

### Passo 4: Fazer primeiro deploy

No repositório local:

```bash
# Criar branch staging
git checkout -b staging
git push origin staging

# Trigger workflow manualmente no GitHub:
# Actions → Deploy to Staging → Run workflow
```

### Passo 5: Configurar Nginx (na EC2)

```bash
ssh -i instasolutions-deploy-key.pem ubuntu@54.XXX.XXX.XXX

# Instalar Nginx
sudo apt install -y nginx

# Configurar site
sudo nano /etc/nginx/sites-available/instasolutions

# Colar configuração:
```

```nginx
upstream puma {
  server unix:///var/www/instasolutions/shared/tmp/sockets/puma.sock;
}

server {
  listen 80;
  server_name _;

  root /var/www/instasolutions/current/public;
  access_log /var/www/instasolutions/shared/log/nginx.access.log;
  error_log /var/www/instasolutions/shared/log/nginx.error.log info;

  location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  try_files $uri/index.html $uri @puma;
  location @puma {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    proxy_pass http://puma;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}
```

```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/instasolutions /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Configurar Puma como serviço
sudo nano /etc/systemd/system/puma.service
```

```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/instasolutions/current
ExecStart=/home/ubuntu/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable puma
sudo systemctl start puma
sudo systemctl status puma
```

### Passo 6: Testar staging

Acesse: `http://54.XXX.XXX.XXX`

Verifique:
- ✅ Login funciona
- ✅ Dashboard mostra dados corretos
- ✅ Badges de OS com cores corretas
- ✅ Sem caracteres ???? nos nomes
- ✅ Imagens carregam do S3

---

## 🚀 Deploy Production

### Preparação

Production segue os mesmos passos de Staging, mas com:

1. **RDS maior**: db.t3.small (2GB RAM)
2. **EC2 maior**: t3.medium (2 vCPUs, 4GB RAM)
3. **Domínio configurado**: instasolutions.com.br
4. **SSL/HTTPS**: Certificado Let's Encrypt
5. **Backup automático**: RDS snapshots diários
6. **CloudFront** (opcional): CDN para assets

### Diferenças principais:

```yaml
# Production RDS
DB instance class: db.t3.small
Multi-AZ: Yes (alta disponibilidade)
Backup retention: 7 dias
Storage: 50 GB

# Production EC2
Instance type: t3.medium
EBS volume: 30 GB
Elastic IP: Sim (IP fixo)
```

### Deploy workflow

```bash
# Merge staging → main
git checkout main
git merge staging
git push origin main

# Trigger deploy no GitHub:
# Actions → Deploy to Production → Run workflow
```

### Configurar domínio

1. No Route 53 (AWS):
   - Criar Hosted Zone: `instasolutions.com.br`
   - Criar Record Type A: `@` → IP EC2 production
   - Criar Record CNAME: `www` → `instasolutions.com.br`

2. No registro.br:
   - Apontar nameservers para os do Route 53

3. SSL com Certbot:

```bash
# Na EC2 production
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d instasolutions.com.br -d www.instasolutions.com.br
```

---

## 🔍 Troubleshooting

### Erro: Could not connect to RDS

**Causa**: Security Group bloqueando conexão

**Solução**:
1. Acesse RDS Console → Databases → sua instância
2. Clique no Security Group
3. Edite Inbound Rules
4. Adicione: Type: MySQL/Aurora, Source: IP da EC2 (ou Security Group da EC2)

### Erro: Assets não carregam

**Causa**: Precompilação falhou

**Solução**:
```bash
ssh na EC2
cd /var/www/instasolutions/current
RAILS_ENV=production bundle exec rails assets:precompile
sudo systemctl restart puma
```

### Erro: 502 Bad Gateway

**Causa**: Puma não está rodando

**Solução**:
```bash
sudo systemctl status puma
sudo journalctl -u puma -f
sudo systemctl restart puma
```

### Erro: Database migration pending

**Solução**:
```bash
cd /var/www/instasolutions/current
RAILS_ENV=production bundle exec rails db:migrate
sudo systemctl restart puma
```

### Logs úteis

```bash
# Nginx
sudo tail -f /var/log/nginx/error.log

# Puma
sudo journalctl -u puma -f

# Rails
tail -f /var/www/instasolutions/current/log/production.log

# RDS
# Ver no AWS Console → RDS → sua instância → Logs
```

---

## 📊 Monitoramento

### CloudWatch Alarms (recomendado)

Configure alertas para:
- CPU EC2 > 80%
- Memória RDS > 80%
- Disco > 85%
- Status de saúde da aplicação

### Backups

```bash
# Backup manual RDS
aws rds create-db-snapshot \
  --db-instance-identifier instasolutions-production-db \
  --db-snapshot-identifier manual-backup-$(date +%Y%m%d)

# Backup uploads S3
aws s3 sync s3://instasolutions-production-uploads s3://instasolutions-backups-$(date +%Y%m%d)
```

---

## ✅ Checklist Final

### Antes do deploy production:

- [ ] Todos os testes passando em staging
- [ ] Dashboard exibindo valores corretos
- [ ] Badges de OS com cores corretas
- [ ] Encoding UTF-8 funcionando (sem ????)
- [ ] Uploads S3 funcionando
- [ ] Backups RDS configurados
- [ ] SSL/HTTPS configurado
- [ ] Domínio apontando corretamente
- [ ] Secrets GitHub configurados
- [ ] Monitoramento CloudWatch ativo
- [ ] Plano de rollback definido

### Após deploy production:

- [ ] Smoke test: login, criar OS, aprovar proposta
- [ ] Verificar logs sem erros
- [ ] Confirmar emails sendo enviados
- [ ] Testar performance (tempo de resposta)
- [ ] Validar cálculos do Dashboard
- [ ] Backup manual criado

---

## 🆘 Suporte

Em caso de problemas críticos:

1. **Rollback imediato**:
   ```bash
   # No GitHub Actions, encontre o último deploy bem-sucedido
   # Re-execute aquele workflow
   ```

2. **Restaurar banco**:
   ```bash
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier instasolutions-production-db-restored \
     --db-snapshot-identifier [snapshot-id]
   ```

3. **Logs detalhados**:
   ```bash
   ssh na EC2
   cd /var/www/instasolutions/current
   tail -f log/production.log
   ```

---

## 📚 Referências

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deployment.html)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Última atualização**: 2026-01-22  
**Versão**: 1.0  
**Autor**: Equipe Desenvolvimento Insta Solutions
