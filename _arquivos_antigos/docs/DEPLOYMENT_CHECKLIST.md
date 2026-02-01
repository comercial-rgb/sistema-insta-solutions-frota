# ✅ CHECKLIST DE DEPLOY - Produção AWS

**Data:** 27/01/2026  
**Sistema:** Insta Solutions - Gestão de Frota  
**Ambiente:** Production (AWS)

---

## 📋 PRÉ-REQUISITOS

### ✅ Verificações Locais
- [ ] Sistema funcionando 100% no ambiente local
- [ ] Todas as correções testadas e validadas
- [ ] Backup do banco local criado
- [ ] Commits criados no Git

### ✅ Acesso AWS
- [ ] Credenciais AWS IAM configuradas
- [ ] Acesso SSH à EC2 de produção
- [ ] Acesso ao RDS de produção
- [ ] Bucket S3 existente e acessível

### ✅ Domínio e DNS
- [ ] Domínio registrado
- [ ] Acesso ao painel de DNS (Route 53 ou Registro.br)

---

## 📦 FASE 1: PREPARAÇÃO DO CÓDIGO

### 1.1 Verificar Git Status
```powershell
git status
git log --oneline -5
```

### 1.2 Commit das Mudanças
```powershell
# Adicionar arquivos modificados
git add app/helpers/menu_helper.rb
git add app/models/order_service_proposal_status.rb
git add app/grids/order_services_grid.rb
git add scripts/production_data_fixes.sql
git add DEPLOYMENT_CHECKLIST.md

# Criar commit
git commit -m "fix: corrigir menu duplicado, encoding e erro no grid de OS

- Menu: remover duplicação de 'Em aberto' e ajustar ordem
- Encoding: corrigir ?? em múltiplas tabelas
- Grid: adicionar fallback para order_service_invoice_type nil
- Scripts: adicionar correções SQL para produção"

# Verificar
git log -1 --stat
```

### 1.3 Push para GitHub
```powershell
# Push para branch principal
git push origin main

# Verificar no GitHub
# https://github.com/seu-usuario/sistema-insta-solutions-frota
```

---

## 🔐 FASE 2: CONFIGURAR SECRETS NO GITHUB

### 2.1 Acessar GitHub Secrets
1. Ir para: **Settings** → **Secrets and variables** → **Actions**
2. Clicar em **New repository secret**

### 2.2 Secrets Necessários

#### AWS Geral
```
AWS_ACCESS_KEY_ID
Valor: [sua access key da IAM]

AWS_SECRET_ACCESS_KEY
Valor: [sua secret key da IAM]

AWS_REGION
Valor: us-east-1
```

#### EC2 Production
```
EC2_SSH_KEY_PRODUCTION
Valor: [conteúdo completo do arquivo .pem]

PRODUCTION_HOST
Valor: [IP público da EC2, ex: 54.123.45.67]
```

#### RDS Production
```
RDS_HOST
Valor: [endpoint do RDS, ex: instasolutions.xxxxx.rds.amazonaws.com]

RDS_USERNAME
Valor: admin

RDS_PASSWORD
Valor: [senha do RDS]
```

#### S3 Production
```
S3_BUCKET_PRODUCTION
Valor: instasolutions-production-uploads
```

#### Rails Production
```
PRODUCTION_SECRET_KEY_BASE
Valor: [executar localmente: bundle exec rails secret]
```

---

## 💾 FASE 3: BACKUP DO BANCO DE PRODUÇÃO

### 3.1 Conectar via SSH na EC2
```powershell
ssh -i caminho\para\sua-key.pem ubuntu@54.123.45.67
```

### 3.2 Criar Backup Completo
```bash
# No servidor EC2
mysqldump -h instasolutions.xxxxx.rds.amazonaws.com \
          -u admin \
          -p \
          --single-transaction \
          --routines \
          --triggers \
          --databases sistema_insta_solutions_production \
          > backup_pre_deploy_$(date +%Y%m%d_%H%M%S).sql

# Verificar tamanho do backup
ls -lh backup_*.sql

# Upload para S3 (segurança)
aws s3 cp backup_*.sql s3://insta-solutions-backups/
```

### 3.3 Download do Backup (Opcional)
```powershell
# No seu PC local
scp -i sua-key.pem ubuntu@54.123.45.67:/home/ubuntu/backup_*.sql ./
```

---

## 🚀 FASE 4: DEPLOY DO CÓDIGO

### 4.1 Trigger GitHub Actions
1. Ir para: **Actions** → **Deploy to Production**
2. Clicar em **Run workflow**
3. Branch: `main`
4. Clicar em **Run workflow**

### 4.2 Monitorar Deploy
- Acompanhar log em tempo real no GitHub Actions
- Verificar se todos os steps passaram (✅)
- Tempo estimado: 5-10 minutos

### 4.3 Verificar Deploy Manual (se necessário)
```bash
# SSH na EC2
ssh -i sua-key.pem ubuntu@54.123.45.67

# Verificar aplicação
cd /var/www/sistema-insta-solutions
git log -1
bundle list | grep rails

# Verificar serviço
sudo systemctl status puma
sudo systemctl status nginx

# Ver logs
tail -f log/production.log
```

---

## 🗄️ FASE 5: APLICAR CORREÇÕES SQL NO RDS

### 5.1 Upload do Script SQL
```powershell
# No seu PC local
scp -i sua-key.pem scripts/production_data_fixes.sql ubuntu@54.123.45.67:/tmp/
```

### 5.2 Conectar ao RDS e Executar
```bash
# SSH na EC2
ssh -i sua-key.pem ubuntu@54.123.45.67

# Conectar ao MySQL
mysql -h instasolutions.xxxxx.rds.amazonaws.com \
      -u admin \
      -p \
      sistema_insta_solutions_production

# No prompt MySQL:
source /tmp/production_data_fixes.sql

# Verificar resultados das validações
# (O próprio script já executa SELECTs de verificação)
```

### 5.3 Validação Manual
```sql
-- Verificar menu de OS
SELECT id, name FROM order_service_statuses ORDER BY id;

-- Verificar tipos de invoice
SELECT id, name FROM order_service_invoice_types;

-- Amostra de order_services.details
SELECT id, details FROM order_services 
WHERE details IS NOT NULL 
LIMIT 10;

-- Amostra de dados de faturamento
SELECT id, name, invoice_name, invoice_address 
FROM cost_centers 
WHERE invoice_name IS NOT NULL 
LIMIT 5;

-- Sair do MySQL
exit
```

---

## 🌐 FASE 6: CONFIGURAR DNS

### Opção A: AWS Route 53

#### 6.1 Criar Hosted Zone
1. Acessar: [Route 53 Console](https://console.aws.amazon.com/route53/)
2. Clicar em **Hosted zones** → **Create hosted zone**
3. Domain name: `seudominio.com.br`
4. Type: **Public hosted zone**
5. Criar

#### 6.2 Criar Record Sets
```
Tipo: A
Name: (deixar vazio ou @)
Value: [IP público da EC2 Production]
TTL: 300

---

Tipo: CNAME
Name: www
Value: seudominio.com.br
TTL: 300
```

#### 6.3 Atualizar Nameservers no Registro.br
1. Copiar os 4 nameservers do Route 53 (ex: ns-123.awsdns-12.com)
2. Acessar [Registro.br](https://registro.br)
3. Ir em DNS do domínio
4. Atualizar nameservers
5. Aguardar propagação (até 48h, geralmente < 2h)

### Opção B: DNS Externo (Registro.br direto)

```
Tipo: A
Host: @
Valor: [IP público da EC2]

Tipo: CNAME
Host: www
Valor: seudominio.com.br
```

---

## 🔒 FASE 7: CONFIGURAR SSL/HTTPS

### 7.1 Instalar Certbot
```bash
# SSH na EC2
ssh -i sua-key.pem ubuntu@54.123.45.67

# Instalar Certbot
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

### 7.2 Obter Certificado
```bash
# Obter certificado Let's Encrypt
sudo certbot --nginx -d seudominio.com.br -d www.seudominio.com.br

# Seguir instruções:
# - Email: seu@email.com
# - Aceitar termos
# - Redirecionar HTTP → HTTPS: Sim (2)
```

### 7.3 Configurar Renovação Automática
```bash
# Testar renovação
sudo certbot renew --dry-run

# O cron já é configurado automaticamente
```

---

## ✅ FASE 8: VALIDAÇÃO FINAL

### 8.1 Verificações de Sistema
- [ ] Site acessível via HTTPS: `https://seudominio.com.br`
- [ ] Certificado SSL válido (cadeado verde)
- [ ] Redirecionamento HTTP → HTTPS funciona
- [ ] Login funciona corretamente

### 8.2 Verificações de Funcionalidade
- [ ] Menu de OS sem duplicação "Em aberto"
- [ ] Ordem do menu correta (Em reavaliação depois de Em aberto)
- [ ] Listagem de OS não quebra (fallback para tipo nil)
- [ ] Textos sem `??` (nomes, endereços, detalhes)
- [ ] Dados de faturamento corretos
- [ ] Badges de status com cores corretas

### 8.3 Verificações de Performance
```bash
# Tempo de resposta
curl -w "@-" -o /dev/null -s https://seudominio.com.br <<'EOF'
time_namelookup:  %{time_namelookup}\n
time_connect:  %{time_connect}\n
time_total:  %{time_total}\n
EOF

# Status dos serviços
sudo systemctl status puma
sudo systemctl status nginx

# Uso de recursos
free -h
df -h
```

### 8.4 Monitoramento Inicial
```bash
# Acompanhar logs por 5-10 minutos
tail -f log/production.log

# Verificar erros
grep ERROR log/production.log | tail -20
```

---

## 🔄 ROLLBACK (Se Necessário)

### Se algo der errado:

```bash
# 1. Parar serviços
sudo systemctl stop puma

# 2. Restaurar banco
mysql -h RDS_HOST -u admin -p sistema_insta_solutions_production < backup_pre_deploy_*.sql

# 3. Reverter código (no GitHub Actions, re-executar deploy anterior)
cd /var/www/sistema-insta-solutions
git reset --hard COMMIT_ANTERIOR

# 4. Reiniciar
bundle install
RAILS_ENV=production bundle exec rails db:migrate
sudo systemctl start puma
```

---

## 📞 SUPORTE

### Logs Importantes
```bash
# Application logs
tail -f log/production.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Puma logs
sudo journalctl -u puma -f

# System logs
dmesg | tail -50
```

### Contatos
- **Infraestrutura AWS:** [responsável]
- **Desenvolvimento:** [responsável]
- **Suporte DNS:** [responsável]

---

## 📝 PÓS-DEPLOY

- [ ] Documentar problemas encontrados
- [ ] Atualizar documentação técnica
- [ ] Notificar equipe do deploy concluído
- [ ] Monitorar sistema por 24-48h
- [ ] Agendar revisão de performance (1 semana)

---

**✅ Deploy concluído com sucesso!**
