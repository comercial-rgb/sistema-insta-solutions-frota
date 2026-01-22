# 🚀 GUIA: CI/CD Automático com GitHub Actions + AWS

**Data:** 22/01/2026  
**Sistema:** Insta Solutions

---

## 📋 **VISÃO GERAL DO DEPLOY AUTOMÁTICO**

Este guia configura deploy automático do seu repositório Git para AWS:

```
Push no Git → Testes Automáticos → Deploy Staging → Aprovação → Deploy Produção
```

---

## ⚙️ **CONFIGURAÇÃO INICIAL**

### **1. Configurar Secrets no GitHub**

Vá em: `Repositório > Settings > Secrets and variables > Actions > New repository secret`

**Adicione os seguintes secrets:**

```
AWS_ACCESS_KEY_ID              → Sua access key da AWS
AWS_SECRET_ACCESS_KEY          → Sua secret key da AWS
EC2_SSH_KEY_STAGING            → Conteúdo do arquivo .pem (staging)
EC2_SSH_KEY_PRODUCTION         → Conteúdo do arquivo .pem (production)
STAGING_HOST                   → IP ou DNS do servidor staging
PRODUCTION_HOST                → IP ou DNS do servidor production
RDS_HOST                       → Endpoint do RDS
RDS_USERNAME                   → Usuário do banco
RDS_PASSWORD                   → Senha do banco
```

**Como obter AWS Access Keys:**
```
1. AWS Console > IAM > Users > Seu usuário
2. Security credentials > Create access key
3. Copiar Access Key ID e Secret Access Key
```

---

## 🔄 **FLUXO AUTOMÁTICO**

### **Cenário 1: Deploy para STAGING**

```bash
# Desenvolvedor trabalha em uma feature
git checkout -b feature/nova-funcionalidade

# Faz commits
git add .
git commit -m "Implementa nova funcionalidade"

# Merge para branch staging
git checkout staging
git merge feature/nova-funcionalidade
git push origin staging

# 🤖 AUTOMÁTICO A PARTIR DAQUI:
# ✅ GitHub Actions detecta push
# ✅ Roda testes automáticos
# ✅ Se passar, faz deploy para EC2 Staging
# ✅ Notifica equipe (Slack/Email)
```

### **Cenário 2: Deploy para PRODUCTION**

```bash
# Após aprovação em staging
git checkout main
git merge staging
git push origin main

# 🤖 AUTOMÁTICO:
# ✅ Roda testes
# ✅ Faz backup do banco
# ✅ Deploy para EC2 Production
# ✅ Health check
# ✅ Notifica equipe
```

---

## 📝 **WORKFLOWS CRIADOS**

### **1. `.github/workflows/deploy-staging.yml`**
- Acionado por: Push na branch `staging`
- Executa:
  1. Roda testes (RSpec)
  2. Deploy automático para servidor staging
  3. Reinicia aplicação

### **2. `.github/workflows/deploy-production.yml`**
- Acionado por: Push na branch `main`/`master`
- Executa:
  1. Roda testes
  2. Backup automático do banco
  3. Deploy para produção
  4. Health check
  5. Notificação

---

## 🛠️ **CONFIGURAR SERVIDOR EC2 PARA CI/CD**

### **1. Criar usuário deploy (mais seguro que usar ubuntu)**

```bash
# No servidor EC2
sudo adduser deploy
sudo usermod -aG sudo deploy

# Adicionar chave SSH
sudo su - deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Cole a chave pública do GitHub Actions
chmod 600 ~/.ssh/authorized_keys

# Dar permissões na pasta do projeto
sudo chown -R deploy:deploy /var/www/sistema-insta-solutions
```

### **2. Permitir deploy reiniciar serviços sem senha**

```bash
sudo visudo
# Adicionar no final:
deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart puma
```

### **3. Configurar Git no servidor**

```bash
cd /var/www/sistema-insta-solutions

# Configurar para aceitar pushes
git config receive.denyCurrentBranch ignore

# Adicionar hook pós-recebimento (opcional)
nano .git/hooks/post-receive
```

---

## 🎯 **ESTRATÉGIAS DE DEPLOY**

### **Opção A: Deploy Direto (Padrão)**
```yaml
# Configurado nos workflows criados
- Push → Testes → Deploy automático
```

### **Opção B: Deploy com Aprovação Manual**
```yaml
# Em deploy-production.yml, adicionar:
environment:
  name: production
  url: https://seudominio.com.br
# Requer aprovação manual no GitHub antes de deployar
```

**Configurar:**
```
1. GitHub > Settings > Environments > New environment
2. Nome: production
3. Required reviewers: Adicionar pessoas que devem aprovar
4. Save protection rules
```

### **Opção C: Deploy Agendado**
```yaml
# Deploy automático às 2h da manhã
on:
  schedule:
    - cron: '0 2 * * *'  # Todo dia às 2 AM
```

### **Opção D: Deploy Manual pelo GitHub**
```yaml
on:
  workflow_dispatch:  # Ativa botão "Run workflow" no GitHub
```

**Como usar:**
```
1. GitHub > Actions > Deploy to Production
2. Clicar em "Run workflow"
3. Selecionar branch
4. Run
```

---

## 🔍 **MONITORAMENTO E LOGS**

### **Ver Status dos Workflows**
```
GitHub > Actions > Ver histórico de deploys
```

### **Logs no Servidor**
```bash
# Staging
ssh ubuntu@staging-server
tail -f /var/www/sistema-insta-solutions/log/staging.log

# Production
ssh ubuntu@production-server
tail -f /var/www/sistema-insta-solutions/log/production.log
```

### **Receber Notificações**

#### **Slack:**
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

#### **Email:**
```yaml
- name: Send Email
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 587
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Deploy Status - ${{ job.status }}
    body: Deploy to production ${{ job.status }}
    to: equipe@empresa.com.br
```

#### **Discord:**
```yaml
- name: Discord notification
  uses: Ilshidur/action-discord@master
  env:
    DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
  with:
    args: 'Deploy to production completed!'
```

---

## 🔄 **ROLLBACK (REVERTER DEPLOY)**

### **Método 1: Via Git**
```bash
# Localmente
git revert HEAD
git push origin main

# GitHub Actions automaticamente faz deploy da versão anterior
```

### **Método 2: Manual no Servidor**
```bash
ssh ubuntu@production-server
cd /var/www/sistema-insta-solutions

# Ver commits recentes
git log --oneline -10

# Voltar para commit anterior
git reset --hard <hash-do-commit-anterior>

# Rollback migration (se necessário)
RAILS_ENV=production bundle exec rails db:rollback

# Recompilar assets
RAILS_ENV=production bundle exec rails assets:precompile

# Restart
touch tmp/restart.txt
```

### **Método 3: Restaurar Backup**
```bash
# Listar backups
aws s3 ls s3://insta-solutions-backups/

# Baixar backup
aws s3 cp s3://insta-solutions-backups/backup_20260122_140000.sql /tmp/

# Restaurar
mysql -h seu-rds-endpoint.rds.amazonaws.com \
      -u admin \
      -p \
      sistema_insta_solutions_production < /tmp/backup_20260122_140000.sql
```

---

## 🧪 **TESTE LOCAL DOS WORKFLOWS**

Instale `act` para testar workflows localmente:

```bash
# Windows (PowerShell)
choco install act-cli

# Testar workflow
act -W .github/workflows/deploy-staging.yml
```

---

## 📊 **ALTERNATIVAS AO GITHUB ACTIONS**

### **AWS CodePipeline**
```yaml
# buildspec.yml
version: 0.2
phases:
  install:
    runtime-versions:
      ruby: 3.2
  build:
    commands:
      - bundle install
      - RAILS_ENV=production rails db:migrate
      - RAILS_ENV=production rails assets:precompile
artifacts:
  files:
    - '**/*'
```

### **GitLab CI/CD**
```yaml
# .gitlab-ci.yml
stages:
  - test
  - deploy

test:
  stage: test
  script:
    - bundle install
    - rails db:test:prepare
    - rspec

deploy_staging:
  stage: deploy
  script:
    - ssh deploy@staging-server 'cd /var/www/app && git pull && bundle install'
  only:
    - staging

deploy_production:
  stage: deploy
  script:
    - ssh deploy@production-server 'cd /var/www/app && git pull && bundle install'
  only:
    - main
  when: manual
```

---

## ✅ **CHECKLIST DE CONFIGURAÇÃO**

### **No GitHub:**
- [ ] Secrets configurados
- [ ] Workflows criados (`.github/workflows/`)
- [ ] Environment "production" criado (se usar aprovação)
- [ ] Notificações configuradas (Slack/Email)

### **No Servidor EC2:**
- [ ] Usuário deploy criado
- [ ] Chaves SSH configuradas
- [ ] Permissões sudo sem senha
- [ ] Git configurado
- [ ] Aplicação rodando

### **No AWS:**
- [ ] IAM user com permissões corretas
- [ ] Security Groups liberados
- [ ] S3 bucket para backups
- [ ] RDS acessível pelos EC2

---

## 🆘 **TROUBLESHOOTING**

### **Erro: "Permission denied (publickey)"**
```bash
# Verificar se a chave SSH está correta no GitHub Secrets
# Regenerar chave se necessário
ssh-keygen -t rsa -b 4096 -C "deploy@github-actions"
```

### **Erro: "Host key verification failed"**
```yaml
# Adicionar no workflow:
- run: ssh -o StrictHostKeyChecking=no ...
```

### **Erro: "Bundle install fails"**
```bash
# No servidor, limpar bundle cache
rm -rf vendor/bundle
bundle install
```

### **Deploy não acontece**
```
1. Verificar logs no GitHub Actions
2. Verificar se branch está correta
3. Verificar se secrets estão configurados
```

---

## 📞 **PRÓXIMOS PASSOS**

1. ✅ **Configurar secrets no GitHub**
2. ✅ **Testar workflow de staging** (push para branch staging)
3. ✅ **Validar deploy em staging**
4. ✅ **Configurar aprovação para production** (opcional)
5. ✅ **Testar deploy em production**
6. ✅ **Configurar notificações**
7. ✅ **Documentar processo para equipe**

---

**Documentação criada por:** GitHub Copilot  
**Data:** 22/01/2026  
**Versão:** 1.0
