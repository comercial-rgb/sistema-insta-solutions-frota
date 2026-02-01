# 🚀 GUIA COMPLETO - DEPLOY AWS
## Sistema Frota Insta Solutions - 1.000+ Usuários

**Domínio:** app.frotainstasolutions.com.br  
**Plataforma:** Amazon Web Services (AWS)  
**Data:** Janeiro 2026

---

## 📋 ÍNDICE

1. [Visão Geral da Arquitetura](#visão-geral)
2. [Criar Conta AWS](#passo-1-criar-conta-aws)
3. [Configurar EC2 (Aplicação)](#passo-2-ec2-aplicação)
4. [Configurar RDS (Banco de Dados)](#passo-3-rds-mysql)
5. [Configurar S3 (Storage)](#passo-4-s3-storage)
6. [Configurar VPC e Segurança](#passo-5-segurança)
7. [Deploy da Aplicação](#passo-6-deploy)
8. [SSL e Domínio](#passo-7-ssl)
9. [Backup e Monitoramento](#passo-8-backup)
10. [Custos Detalhados](#custos)

---

## 🏗️ VISÃO GERAL DA ARQUITETURA

```
                    INTERNET
                       │
                       ▼
        ┌──────────────────────────┐
        │   Route 53 (DNS)         │
        │   app.frotainstasol...   │
        └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   CloudFront (CDN)       │ ◄── Opcional mas recomendado
        │   Cache global           │
        └──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────┐
│  VPC (Rede Virtual Privada)                 │
│                                             │
│  ┌────────────────┐    ┌────────────────┐  │
│  │  PUBLIC SUBNET │    │ PRIVATE SUBNET │  │
│  │                │    │                │  │
│  │  ┌──────────┐  │    │  ┌──────────┐  │  │
│  │  │   EC2    │  │    │  │   RDS    │  │  │
│  │  │  Rails   │◄─┼────┼─▶│  MySQL   │  │  │
│  │  │  16GB    │  │    │  │  16GB    │  │  │
│  │  │  8 cores │  │    │  │  4 cores │  │  │
│  │  └──────────┘  │    │  └──────────┘  │  │
│  │                │    │                │  │
│  │  IP Público    │    │  IP Privado    │  │
│  └────────────────┘    └────────────────┘  │
└─────────────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   S3 Bucket              │
        │   Uploads/Arquivos       │
        │   Backups                │
        └──────────────────────────┘
```

**Região recomendada:** `sa-east-1` (São Paulo, Brasil)

---

## 📝 PASSO 1: CRIAR CONTA AWS

### 1.1 Criar Conta

1. Acesse: https://aws.amazon.com/pt/
2. Clique em **"Criar uma conta da AWS"**
3. Preencha:
   - Email
   - Senha
   - Nome da conta (ex: Frota Insta Solutions)
4. **Importante:** Você precisará de:
   - ✅ Cartão de crédito válido
   - ✅ Telefone para verificação
   - ✅ Documento de identidade

### 1.2 Configurar Faturamento

1. Acesse: **Billing Dashboard**
2. Configure:
   - ✅ Alertas de faturamento
   - ✅ Budget Alert (ex: avisar se ultrapassar R$ 1.500/mês)
   - ✅ Free Tier Alerts

```
Alerta recomendado:
- Orçamento mensal: R$ 1.500 (USD 300)
- Notificar quando atingir: 80% e 100%
- Email de notificação: seu-email@empresa.com
```

### 1.3 Criar Usuário IAM (Segurança)

**⚠️ NUNCA use a conta root para operações do dia a dia!**

1. Acesse: **IAM** (Identity and Access Management)
2. Clique: **Users** → **Add users**
3. Configurar:
   ```
   Username: admin-frotainstasolutions
   Access type: 
     ☑ Programmatic access (para CLI/scripts)
     ☑ AWS Management Console access
   ```
4. Permissions:
   - Attach existing policy: **AdministratorAccess**
5. **IMPORTANTE:** Salvar credenciais:
   ```
   Access Key ID: AKIAXXXXXXXXXXXXXXXX
   Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Console login: https://[ACCOUNT-ID].signin.aws.amazon.com/console
   ```

### 1.4 Ativar MFA (Autenticação em 2 fatores)

1. IAM → Users → seu usuário
2. Security credentials → Assign MFA device
3. Use app: **Google Authenticator** ou **Authy**

---

## 🖥️ PASSO 2: EC2 - SERVIDOR DE APLICAÇÃO

### 2.1 Criar Key Pair (Acesso SSH)

1. Acesse: **EC2** → **Network & Security** → **Key Pairs**
2. Clique: **Create key pair**
3. Configurar:
   ```
   Name: frotainstasolutions-keypair
   Key pair type: RSA
   File format: .pem (para Linux/Mac) ou .ppk (para Windows/PuTTY)
   ```
4. **Download** → Salvar em local seguro!
5. **No seu computador:**
   ```powershell
   # Se baixou .pem, converter permissões (no Linux/Mac):
   chmod 400 frotainstasolutions-keypair.pem
   
   # No Windows com PowerShell:
   icacls frotainstasolutions-keypair.pem /inheritance:r
   icacls frotainstasolutions-keypair.pem /grant:r "$($env:USERNAME):(R)"
   ```

### 2.2 Criar Security Group

1. EC2 → **Security Groups** → **Create security group**
2. Configurar:

```
Name: frotainstasolutions-app-sg
Description: Security group para servidor de aplicação
VPC: default (ou criar VPC customizada)

INBOUND RULES:
┌──────────┬──────────┬────────────┬─────────────────────┐
│ Type     │ Protocol │ Port Range │ Source              │
├──────────┼──────────┼────────────┼─────────────────────┤
│ SSH      │ TCP      │ 22         │ Meu IP / 0.0.0.0/0  │
│ HTTP     │ TCP      │ 80         │ 0.0.0.0/0           │
│ HTTPS    │ TCP      │ 443        │ 0.0.0.0/0           │
│ Custom   │ TCP      │ 3000       │ 0.0.0.0/0 (teste)   │
└──────────┴──────────┴────────────┴─────────────────────┘

OUTBOUND RULES:
All traffic → 0.0.0.0/0 (permitir tudo)
```

### 2.3 Lançar Instância EC2

1. EC2 → **Instances** → **Launch instances**

#### Step 1: Name and tags
```
Name: frotainstasolutions-app
Environment: production
Application: rails
```

#### Step 2: Application and OS Images (AMI)
```
AMI: Ubuntu Server 22.04 LTS
Architecture: 64-bit (x86)
```

#### Step 3: Instance type

**Para 1.000+ usuários:**

```
OPÇÃO 1 (Econômica):
Type: t3.xlarge
vCPUs: 4
RAM: 16 GB
Network: Up to 5 Gbps
Custo: ~$0.1664/hora = ~$120/mês

OPÇÃO 2 (Recomendada):
Type: t3.2xlarge
vCPUs: 8
RAM: 32 GB
Network: Up to 5 Gbps
Custo: ~$0.3328/hora = ~$240/mês

OPÇÃO 3 (Performance):
Type: c6i.2xlarge
vCPUs: 8 (performance otimizada)
RAM: 16 GB
Custo: ~$0.34/hora = ~$245/mês
```

**Escolha recomendada:** `t3.2xlarge` (8 vCPUs, 32GB RAM)

#### Step 4: Key pair
```
Select: frotainstasolutions-keypair (criado anteriormente)
```

#### Step 5: Network settings
```
VPC: default (ou custom)
Subnet: No preference (ou escolher availability zone)
Auto-assign public IP: Enable
Firewall (security groups): frotainstasolutions-app-sg
```

#### Step 6: Configure storage

```
Root volume:
- Size: 100 GB (mínimo 50 GB)
- Volume type: gp3 (SSD - melhor performance)
- IOPS: 3000
- Throughput: 125 MB/s
- Delete on termination: Yes (ou No para manter dados)

Optional: Adicionar volume extra para logs
- Add volume: 50 GB gp3 (montado em /var/log)
```

#### Step 7: Advanced details (Opcional)

**User data** (executar ao iniciar - opcional):
```bash
#!/bin/bash
apt-get update
apt-get upgrade -y
apt-get install -y curl git build-essential
```

### 2.4 Alocar Elastic IP (IP fixo)

**⚠️ IMPORTANTE:** Por padrão, o IP público muda ao reiniciar!

1. EC2 → **Elastic IPs** → **Allocate Elastic IP address**
2. Configurar:
   ```
   Network Border Group: sa-east-1
   Public IPv4 address pool: Amazon pool
   ```
3. Clique: **Allocate**
4. **Associar à instância:**
   - Actions → **Associate Elastic IP address**
   - Instance: frotainstasolutions-app
   - Private IP: (selecionar automaticamente)
   - Clique: **Associate**

**Anote o Elastic IP:** ex: `15.228.XXX.XXX`

---

## 🗄️ PASSO 3: RDS - BANCO DE DADOS MYSQL

### 3.1 Criar Security Group para RDS

1. EC2 → **Security Groups** → **Create security group**

```
Name: frotainstasolutions-rds-sg
Description: Security group para RDS MySQL

INBOUND RULES:
┌──────────┬──────────┬────────────┬─────────────────────────┐
│ Type     │ Protocol │ Port Range │ Source                  │
├──────────┼──────────┼────────────┼─────────────────────────┤
│ MySQL    │ TCP      │ 3306       │ frotainstasolutions-    │
│          │          │            │ app-sg (security group) │
└──────────┴──────────┴────────────┴─────────────────────────┘

Isso permite apenas o servidor EC2 acessar o banco!
```

### 3.2 Criar Subnet Group

1. RDS → **Subnet groups** → **Create DB subnet group**

```
Name: frotainstasolutions-subnet-group
Description: Subnet group para RDS
VPC: default (ou sua VPC)

Add subnets:
- Selecione pelo menos 2 availability zones
- sa-east-1a
- sa-east-1b
```

### 3.3 Criar Instância RDS

1. RDS → **Databases** → **Create database**

#### Engine options
```
Engine type: MySQL
Edition: MySQL Community
Version: 8.0.35 (ou mais recente)
```

#### Templates
```
☐ Production
☑ Dev/Test (mais barato)
☐ Free tier (não suporta carga alta)
```

#### Settings
```
DB instance identifier: frotainstasolutions-db

Credentials:
  Master username: admin
  
  Master password: [CRIAR SENHA FORTE]
  Exemplo: Fr0t@1nst@S0lut10ns2026!#
  
  ⚠️ ANOTAR SENHA EM LOCAL SEGURO!
```

#### Instance configuration

**Para 1.000+ usuários:**

```
OPÇÃO 1 (Econômica):
DB instance class: db.t3.large
vCPUs: 2
RAM: 8 GB
Custo: ~$0.146/hora = ~$105/mês

OPÇÃO 2 (Recomendada):
DB instance class: db.m6i.xlarge
vCPUs: 4
RAM: 16 GB
Network: 10 Gbps
Custo: ~$0.262/hora = ~$189/mês

OPÇÃO 3 (Performance):
DB instance class: db.m6i.2xlarge
vCPUs: 8
RAM: 32 GB
Custo: ~$0.524/hora = ~$378/mês
```

**Escolha recomendada:** `db.m6i.xlarge` (4 vCPUs, 16GB RAM)

#### Storage
```
Storage type: gp3 (SSD)
Allocated storage: 200 GB (mínimo 100 GB)
Storage autoscaling: Enable
Maximum storage threshold: 500 GB

IOPS: 3000
Throughput: 125 MB/s
```

#### Availability & durability
```
☐ Multi-AZ deployment (dobra o custo, alta disponibilidade)
   Recomendado apenas se uptime 99.99% for crítico
```

#### Connectivity
```
VPC: default (ou sua VPC)
Subnet group: frotainstasolutions-subnet-group
Public access: No (mais seguro - apenas EC2 acessa)
VPC security group: frotainstasolutions-rds-sg
Availability Zone: No preference
```

#### Database authentication
```
Password authentication (padrão)
```

#### Additional configuration

```
Initial database name: sistema_insta_solutions_production
  ⚠️ IMPORTANTE: Criar já com o nome do banco!

DB parameter group: default.mysql8.0
Option group: default:mysql-8-0

Backup:
  ☑ Enable automatic backups
  Backup retention period: 7 days (mínimo)
  Backup window: 03:00-04:00 UTC (escolher horário baixo uso)
  
  ☑ Copy tags to snapshots

Encryption:
  ☑ Enable encryption
  KMS key: (default) aws/rds

Monitoring:
  ☑ Enable Enhanced Monitoring
  Granularity: 60 seconds
  
Log exports (marcar todos):
  ☑ Error log
  ☑ General log
  ☑ Slow query log

Maintenance:
  ☐ Enable auto minor version upgrade (cuidado em produção)
  Maintenance window: Sun 04:00-05:00 UTC
  
Deletion protection:
  ☑ Enable deletion protection (impede deleção acidental)
```

### 3.4 Aguardar Criação

- Tempo: ~10-15 minutos
- Status: **Creating** → **Available**

### 3.5 Obter Endpoint

1. RDS → Databases → frotainstasolutions-db
2. **Connectivity & security** → **Endpoint**
3. **Anotar:**
   ```
   Endpoint: frotainstasolutions-db.xxxxxxxxx.sa-east-1.rds.amazonaws.com
   Port: 3306
   ```

---

## 📦 PASSO 4: S3 - STORAGE

### 4.1 Criar Bucket S3

1. S3 → **Create bucket**

```
Bucket name: frotainstasolutions-production
  ⚠️ Nome deve ser único globalmente!
  Sugestão: frotainstasolutions-prod-2026

AWS Region: sa-east-1 (South America - São Paulo)

Object Ownership:
  ○ ACLs disabled (recommended)
  
Block Public Access:
  ☑ Block all public access (mais seguro)
  Arquivos serão acessados via credenciais AWS

Bucket Versioning:
  ☑ Enable (permite recuperar versões antigas)

Default encryption:
  ☑ Enable
  Encryption type: SSE-S3 (padrão AWS)
```

### 4.2 Criar Usuário IAM para S3

1. IAM → **Users** → **Add users**

```
Username: frotainstasolutions-s3-user
Access type: ☑ Programmatic access (apenas)
```

2. **Permissions:**
   - Attach policies directly
   - Criar política customizada: **Create policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::frotainstasolutions-production",
        "arn:aws:s3:::frotainstasolutions-production/*"
      ]
    }
  ]
}
```

Nome da política: `frotainstasolutions-s3-policy`

3. **Finalizar e obter credenciais:**
   ```
   Access key ID: AKIAXXXXXXXXXXXXXXXX
   Secret access key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   
   ⚠️ SALVAR EM LOCAL SEGURO!
   ```

### 4.3 Configurar CORS (se necessário)

Se precisar upload direto do navegador:

1. S3 → Bucket → **Permissions** → **CORS**

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["https://app.frotainstasolutions.com.br"],
    "ExposeHeaders": ["ETag"]
  }
]
```

### 4.4 Lifecycle Policy (Opcional - economizar)

Para mover backups antigos para storage mais barato:

1. S3 → Bucket → **Management** → **Lifecycle rules**

```
Rule name: move-old-backups
Scope: backups/ (prefixo)

Transitions:
- After 30 days → S3 Glacier Instant Retrieval
- After 90 days → S3 Glacier Deep Archive

Expiration:
- After 365 days → Delete permanently
```

---

## 🔐 PASSO 5: CONFIGURAR SEGURANÇA

### 5.1 Configurar VPC (Opcional mas Recomendado)

Para produção séria, criar VPC customizada:

1. VPC → **Create VPC**

```
Name: frotainstasolutions-vpc
IPv4 CIDR: 10.0.0.0/16

Subnets:
- Public Subnet 1:  10.0.1.0/24 (sa-east-1a) - EC2
- Public Subnet 2:  10.0.2.0/24 (sa-east-1b) - EC2 backup
- Private Subnet 1: 10.0.10.0/24 (sa-east-1a) - RDS
- Private Subnet 2: 10.0.11.0/24 (sa-east-1b) - RDS backup
```

### 5.2 Configurar CloudWatch Alarms

1. CloudWatch → **Alarms** → **Create alarm**

**Alarmes recomendados:**

```
1. CPU EC2 > 80%
   Metric: CPUUtilization
   Instance: frotainstasolutions-app
   Threshold: > 80% por 5 minutos
   Action: Enviar email

2. RDS Connections > 400
   Metric: DatabaseConnections
   DBInstance: frotainstasolutions-db
   Threshold: > 400
   Action: Enviar email

3. RDS Storage < 20%
   Metric: FreeStorageSpace
   Threshold: < 20 GB
   Action: Enviar email

4. Billing > $300
   Metric: EstimatedCharges
   Threshold: > $300
   Action: Enviar email URGENTE
```

---

## 🚀 PASSO 6: DEPLOY DA APLICAÇÃO

### 6.1 Conectar ao EC2

**No PowerShell (Windows):**

```powershell
# Conectar via SSH
ssh -i "frotainstasolutions-keypair.pem" ubuntu@[ELASTIC_IP]

# Exemplo:
ssh -i "frotainstasolutions-keypair.pem" ubuntu@15.228.XXX.XXX
```

**Ou usar PuTTY (Windows):**
1. Converter .pem para .ppk com PuTTYgen
2. Conectar com PuTTY usando .ppk

### 6.2 Configurar Servidor (Primeira vez)

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y curl git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libmysqlclient-dev nodejs npm nginx certbot \
  python3-certbot-nginx redis-server htop

# Instalar rbenv (Ruby)
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Instalar Ruby 3.3.0
rbenv install 3.3.0
rbenv global 3.3.0

# Verificar
ruby -v
# Deve mostrar: ruby 3.3.0

# Instalar Bundler
gem install bundler
rbenv rehash

# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar AWS CLI
aws configure
# AWS Access Key ID: [SUA_KEY_DO_S3_USER]
# AWS Secret Access Key: [SUA_SECRET]
# Default region: sa-east-1
# Default output format: json
```

### 6.3 Clonar e Configurar Aplicação

```bash
# Criar estrutura
sudo mkdir -p /var/www/frotainstasolutions
sudo chown -R ubuntu:ubuntu /var/www/frotainstasolutions

# Clonar repositório
cd /var/www/frotainstasolutions
git clone [URL_DO_SEU_REPOSITORIO] production
cd production

# Ou fazer upload via SCP do seu computador:
# scp -i keypair.pem -r /caminho/local ubuntu@[IP]:/var/www/frotainstasolutions/production

# Configurar environment
cp config/application.yml.example config/application.yml
nano config/application.yml
```

**Editar config/application.yml:**

```yaml
# PRODUÇÃO AWS
DATABASE_DATABASE_PRODUCTION: "sistema_insta_solutions_production"
DATABASE_USERNAME_PRODUCTION: "admin"
DATABASE_PASSWORD_PRODUCTION: "Fr0t@1nst@S0lut10ns2026!#"
DATABASE_HOST_PRODUCTION: "frotainstasolutions-db.xxxxxxxxx.sa-east-1.rds.amazonaws.com"
DATABASE_PORT_PRODUCTION: "3306"

# Host
HOST: "app.frotainstasolutions.com.br"

# AWS S3
AWS_ACCESS_KEY_ID: "AKIAXXXXXXXXXXXXXXXX"
AWS_SECRET_ACCESS_KEY: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
AWS_REGION: "sa-east-1"
AWS_BUCKET: "frotainstasolutions-production"

# Redis
REDIS_URL: "redis://localhost:6379/0"

# SMTP (configurar seu provedor)
SMTP_ADDRESS: "smtp.gmail.com"
SMTP_PORT: "587"
SMTP_USERNAME: "seuemail@gmail.com"
SMTP_PASSWORD: "sua_senha_app"

# Secret Key Base
SECRET_KEY_BASE: "[GERAR_ABAIXO]"
```

**Gerar Secret Key:**

```bash
cd /var/www/frotainstasolutions/production
RAILS_ENV=production bundle exec rails secret
# Copiar resultado para application.yml
```

### 6.4 Instalar Dependências e Preparar

```bash
cd /var/www/frotainstasolutions/production

# Instalar gems
bundle install --deployment --without development test

# Instalar Node packages
npm install --production

# Configurar banco (primeira vez)
RAILS_ENV=production bundle exec rails db:create
RAILS_ENV=production bundle exec rails db:migrate

# Se já tem dump do banco antigo:
mysql -h frotainstasolutions-db.xxxxx.rds.amazonaws.com \
  -u admin -p sistema_insta_solutions_production < backup.sql

# Compilar assets
RAILS_ENV=production bundle exec rails assets:precompile

# Ajustar permissões
chmod -R 755 /var/www/frotainstasolutions/production
chmod -R 777 tmp log storage
```

### 6.5 Configurar Serviços

**A. Copiar configurações criadas anteriormente:**

```bash
# Puma service
sudo cp config/systemd/frotainstasolutions.service /etc/systemd/system/

# Ajustar paths se necessário
sudo nano /etc/systemd/system/frotainstasolutions.service
# Trocar 'deploy' por 'ubuntu' se necessário

# Nginx
sudo cp config/nginx/frotainstasolutions.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/frotainstasolutions.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Testar nginx
sudo nginx -t

# Iniciar serviços
sudo systemctl daemon-reload
sudo systemctl enable frotainstasolutions
sudo systemctl start frotainstasolutions
sudo systemctl restart nginx

# Verificar status
sudo systemctl status frotainstasolutions
sudo systemctl status nginx
```

### 6.6 Testar Aplicação

```bash
# Ver logs
tail -f /var/www/frotainstasolutions/production/log/production.log

# Testar localmente
curl http://localhost:3000

# Testar via IP público
curl http://[ELASTIC_IP]
```

---

## 🌐 PASSO 7: DNS E SSL

### 7.1 Configurar DNS no Route 53 (Recomendado)

**Opção A: Migrar domínio para Route 53**

1. Route 53 → **Hosted zones** → **Create hosted zone**
2. Domain name: `frotainstasolutions.com.br`
3. Type: Public hosted zone

4. **Criar registro A:**
   ```
   Record name: app
   Record type: A
   Value: [ELASTIC_IP]
   TTL: 300
   ```

5. **Atualizar Name Servers no Registro.br:**
   - Route 53 vai fornecer 4 name servers
   - Exemplo: ns-123.awsdns-12.com
   - Copiar e colar no painel do Registro.br

**Opção B: Manter DNS atual**

No painel do seu provedor de DNS:
```
Tipo: A
Nome: app
Valor: [ELASTIC_IP]
TTL: 3600
```

### 7.2 Configurar SSL com Let's Encrypt

```bash
# Conectar ao EC2
ssh -i keypair.pem ubuntu@[ELASTIC_IP]

# Obter certificado
sudo certbot --nginx -d app.frotainstasolutions.com.br

# Responder:
# - Email: seu-email@empresa.com
# - Termos: Yes
# - Redirect HTTP to HTTPS: Yes (opção 2)

# Testar renovação
sudo certbot renew --dry-run

# Certificado renova automaticamente via cron
```

### 7.3 Testar HTTPS

Abrir navegador: https://app.frotainstasolutions.com.br

✅ Verificar:
- Certificado SSL válido (cadeado verde)
- Site carrega corretamente
- Login funciona
- Upload de arquivos funciona

---

## 💾 PASSO 8: BACKUP E MONITORAMENTO

### 8.1 Backup Automático RDS

**Já configurado!** RDS faz backup automático diário.

**Para backup manual:**
1. RDS → Databases → frotainstasolutions-db
2. Actions → **Take snapshot**
3. Nome: `manual-backup-2026-01-26`

### 8.2 Backup da Aplicação

**Configurar script de backup:**

```bash
# Editar script
sudo nano /usr/local/bin/backup-frotainstasolutions-aws.sh
```

```bash
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="s3://frotainstasolutions-production/backups"
APP_DIR="/var/www/frotainstasolutions/production"

# Backup de arquivos da aplicação
tar -czf /tmp/app_backup_$DATE.tar.gz \
  $APP_DIR/storage \
  $APP_DIR/public/uploads \
  $APP_DIR/config/application.yml

# Upload para S3
aws s3 cp /tmp/app_backup_$DATE.tar.gz $S3_BUCKET/

# Limpar arquivo local
rm /tmp/app_backup_$DATE.tar.gz

# Limpar backups antigos no S3 (manter 30 dias)
aws s3 ls $S3_BUCKET/ | while read -r line; do
  createDate=$(echo $line|awk {'print $1" "$2'})
  createDate=$(date -d "$createDate" +%s)
  olderThan=$(date --date "30 days ago" +%s)
  if [[ $createDate -lt $olderThan ]]; then
    fileName=$(echo $line|awk {'print $4'})
    aws s3 rm $S3_BUCKET/$fileName
  fi
done

echo "Backup concluído: $DATE"
```

```bash
# Tornar executável
sudo chmod +x /usr/local/bin/backup-frotainstasolutions-aws.sh

# Agendar (diário às 3h)
sudo crontab -e
0 3 * * * /usr/local/bin/backup-frotainstasolutions-aws.sh >> /var/log/backup.log 2>&1
```

### 8.3 Monitoramento com CloudWatch

**Já está ativo!** AWS monitora automaticamente.

**Ver métricas:**
1. CloudWatch → **Dashboards** → **Create dashboard**
2. Nome: `frotainstasolutions-monitoring`
3. Adicionar widgets:
   - EC2 CPU Utilization
   - EC2 Network In/Out
   - RDS CPU Utilization
   - RDS Database Connections
   - RDS Free Storage Space

---

## 💰 CUSTOS DETALHADOS AWS

### Custo Mensal Estimado (sa-east-1)

```
┌──────────────────────────────────────────────────┐
│ SERVIÇO                  │ CONFIG      │ CUSTO   │
├──────────────────────────┼─────────────┼─────────┤
│ EC2 (Aplicação)          │ t3.2xlarge  │ $240    │
│ RDS MySQL (Banco)        │ m6i.xlarge  │ $189    │
│ EBS Storage (EC2)        │ 100 GB gp3  │ $8      │
│ EBS Storage (RDS)        │ 200 GB gp3  │ $16     │
│ S3 Storage               │ 100 GB      │ $2      │
│ S3 Requests              │ ~1M req     │ $1      │
│ Data Transfer Out        │ 500 GB      │ $45     │
│ Elastic IP               │ 1 IP        │ $3.60   │
│ RDS Backup Storage       │ 200 GB      │ $0      │
│ CloudWatch (básico)      │ -           │ $0      │
│ Route 53 (opcional)      │ 1 zone      │ $0.50   │
├──────────────────────────┴─────────────┼─────────┤
│ SUBTOTAL                               │ $505.10 │
│                                        │         │
│ IMPOSTOS (IOF 6.38%)                   │ $32.23  │
│ CONVERSÃO (1 USD = R$ 5.00)            │         │
├────────────────────────────────────────┼─────────┤
│ TOTAL MENSAL (BRL)                     │ R$2.687 │
└────────────────────────────────────────┴─────────┘

EXTRAS OPCIONAIS:
├─ CloudFront CDN                        │ $50-100 │
├─ Load Balancer                         │ $20     │
├─ Certificado SSL (ACM)                 │ GRÁTIS  │
└─ Route 53                              │ $0.50   │
```

### Otimizar Custos

**1. Reserved Instances (Desconto de 30-60%)**

```
Comprar 1 ano de reserva:
- EC2 t3.2xlarge: $240/mês → $150/mês (37% off)
- RDS m6i.xlarge: $189/mês → $120/mês (36% off)

ECONOMIA: ~$160/mês = $1.920/ano
```

**2. Savings Plans**

```
Compromisso: Gastar $300/mês por 1 ano
Desconto: 30-40% em EC2 e RDS
```

**3. Usar Spot Instances (Não recomendado para produção)**

**4. Redimensionar se necessário:**

```
Se carga real for menor:
- EC2: t3.2xlarge → t3.xlarge (economiza $120/mês)
- RDS: m6i.xlarge → db.t3.large (economiza $85/mês)
```

---

## ✅ CHECKLIST FINAL AWS

### Infraestrutura

- [ ] Conta AWS criada e configurada
- [ ] Usuário IAM criado (não usar root)
- [ ] MFA ativado
- [ ] Billing alerts configurados
- [ ] EC2 criado e rodando (t3.2xlarge)
- [ ] Elastic IP alocado e associado
- [ ] RDS MySQL criado e disponível
- [ ] S3 bucket criado
- [ ] Security Groups configurados
- [ ] Backup RDS automático ativo

### Aplicação

- [ ] Código deployado no EC2
- [ ] Dependências instaladas
- [ ] Banco migrado
- [ ] Assets compilados
- [ ] Puma rodando (systemd)
- [ ] Nginx configurado
- [ ] Redis rodando
- [ ] Logs funcionando

### DNS e SSL

- [ ] DNS apontando para Elastic IP
- [ ] SSL configurado (Let's Encrypt)
- [ ] HTTPS funcionando
- [ ] Redirect HTTP → HTTPS ativo

### Segurança e Backup

- [ ] Security groups restritivos
- [ ] Acesso SSH apenas com key pair
- [ ] Backup automático RDS (7 dias)
- [ ] Backup aplicação para S3 (diário)
- [ ] CloudWatch alarms configurados
- [ ] Logs sendo coletados

### Testes

- [ ] Site acessível via HTTPS
- [ ] Login funcionando
- [ ] Upload para S3 funcionando
- [ ] Emails sendo enviados
- [ ] Performance adequada (< 500ms)
- [ ] Conexão com banco OK
- [ ] Redis funcionando

---

## 🆘 COMANDOS ÚTEIS AWS

### Conectar ao EC2

```bash
ssh -i frotainstasolutions-keypair.pem ubuntu@[ELASTIC_IP]
```

### Ver logs da aplicação

```bash
tail -f /var/www/frotainstasolutions/production/log/production.log
tail -f /var/www/frotainstasolutions/production/log/puma_error.log
sudo tail -f /var/log/nginx/frotainstasolutions_error.log
```

### Reiniciar serviços

```bash
sudo systemctl restart frotainstasolutions
sudo systemctl restart nginx
sudo systemctl restart redis
```

### Conectar ao RDS MySQL

```bash
mysql -h frotainstasolutions-db.xxxxx.rds.amazonaws.com \
  -u admin -p sistema_insta_solutions_production
```

### Ver métricas EC2

```bash
# CPU
top
htop

# Memória
free -h

# Disco
df -h

# Rede
ifconfig
netstat -tulpn
```

### Backup manual

```bash
# Banco (RDS)
mysqldump -h [RDS_ENDPOINT] -u admin -p sistema_insta_solutions_production > backup.sql

# Upload para S3
aws s3 cp backup.sql s3://frotainstasolutions-production/backups/

# Arquivos da aplicação
tar -czf app_backup.tar.gz storage/ public/uploads/
aws s3 cp app_backup.tar.gz s3://frotainstasolutions-production/backups/
```

---

## 📞 PRÓXIMOS PASSOS

1. ✅ **Criar conta AWS** (se ainda não tem)
2. ✅ **Seguir este guia passo a passo**
3. ✅ **Configurar monitoramento** (CloudWatch)
4. ✅ **Testar carga** (Apache Bench ou k6)
5. ✅ **Documentar credenciais** (em local seguro)
6. ✅ **Treinar equipe** (acesso, deploy, troubleshooting)
7. ✅ **Planejar custos** (Reserved Instances após 1-2 meses)

---

## 🎉 PARABÉNS!

Seu sistema está rodando na AWS com:
- ✅ Alta disponibilidade
- ✅ Escalabilidade
- ✅ Backup automático
- ✅ Monitoramento completo
- ✅ Segurança enterprise

**URL:** https://app.frotainstasolutions.com.br

---

*Criado em: Janeiro 2026*  
*Para deploy em AWS com 1.000+ usuários*
