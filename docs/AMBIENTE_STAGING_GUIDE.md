# 🔄 GUIA: Ambientes de Teste (Staging) e Produção

**Data:** 22/01/2026  
**Sistema:** Insta Solutions

---

## 📋 **VISÃO GERAL**

Este sistema agora suporta **3 ambientes principais**:

```
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│  DEVELOPMENT   │ → │    STAGING     │ → │   PRODUCTION   │
│    (Local)     │    │    (Teste)     │    │   (Público)    │
└────────────────┘    └────────────────┘    └────────────────┘
     Seu PC          Servidor de Testes    Servidor Principal
```

---

## 🎯 **PROPÓSITO DE CADA AMBIENTE**

### **1. Development (Desenvolvimento)**
- 💻 Ambiente local no seu computador
- 🔧 Para desenvolver novas features
- 🐛 Debug e testes rápidos
- ⚡ Mudanças instantâneas (hot reload)

### **2. Staging (Homologação/Teste)**
- 🧪 Cópia do ambiente de produção
- ✅ Para testar features antes de ir ao ar
- 👥 Cliente pode validar funcionalidades
- 🔍 Detectar problemas antes da produção
- 📊 Banco de dados separado (dados de teste)

### **3. Production (Produção)**
- 🚀 Ambiente público
- 👨‍💼 Usuários reais
- 💾 Dados reais e críticos
- 🔒 Máxima segurança e estabilidade

---

## ⚙️ **CONFIGURAÇÃO DOS AMBIENTES**

### **Passo 1: Configurar Variáveis de Ambiente**

Edite o arquivo `config/application.yml` (não commitado no Git):

```yaml
# ========================================
# STAGING/HOMOLOGAÇÃO
# ========================================
DATABASE_DATABASE_STAGING: "sistema_insta_solutions_staging"
DATABASE_USERNAME_STAGING: "root"
DATABASE_PASSWORD_STAGING: "senha_staging"
DATABASE_HOST_STAGING: "192.168.1.100"  # IP do servidor de staging
DATABASE_PORT_STAGING: "3306"
STAGING_HOST: "staging.seudominio.com.br"

# ========================================
# PRODUÇÃO
# ========================================
DATABASE_DATABASE_PRODUCTION: "sistema_insta_solutions_production"
DATABASE_USERNAME_PRODUCTION: "user_producao"
DATABASE_PASSWORD_PRODUCTION: "senha_forte_producao"
DATABASE_HOST_PRODUCTION: "192.168.1.200"  # IP do servidor de produção
DATABASE_PORT_PRODUCTION: "3306"
```

### **Passo 2: Criar Bancos de Dados**

**No servidor de STAGING:**
```bash
mysql -u root -p
CREATE DATABASE sistema_insta_solutions_staging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'root'@'localhost' IDENTIFIED BY 'senha_staging';
GRANT ALL PRIVILEGES ON sistema_insta_solutions_staging.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

**No servidor de PRODUÇÃO:**
```bash
mysql -u root -p
CREATE DATABASE sistema_insta_solutions_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'user_producao'@'localhost' IDENTIFIED BY 'senha_forte_producao';
GRANT ALL PRIVILEGES ON sistema_insta_solutions_production.* TO 'user_producao'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

## 🚀 **FLUXO DE DEPLOY: DESENVOLVIMENTO → STAGING → PRODUÇÃO**

### **FASE 1: Desenvolvimento Local**

```powershell
# 1. Desenvolver a feature localmente
git checkout -b feature/nova-funcionalidade

# 2. Fazer commits
git add .
git commit -m "Adiciona nova funcionalidade X"

# 3. Testar localmente
rails server
# Testar no navegador: http://localhost:3000
```

---

### **FASE 2: Deploy para STAGING (Teste)**

#### **A. Fazer merge para branch de staging**
```powershell
# Fazer merge na branch de staging
git checkout staging  # ou criar: git checkout -b staging
git merge feature/nova-funcionalidade
git push origin staging
```

#### **B. No servidor de STAGING:**

```bash
# 1. Conectar ao servidor
ssh usuario@servidor-staging

# 2. Ir para a pasta do projeto
cd /var/www/sistema-insta-solutions

# 3. Baixar as mudanças
git pull origin staging

# 4. Instalar dependências (se houver novas)
bundle install

# 5. Executar migrations
RAILS_ENV=staging bundle exec rails db:migrate

# 6. Recompilar assets
RAILS_ENV=staging bundle exec rails assets:precompile

# 7. Reiniciar o servidor
sudo systemctl restart puma-staging
# OU: touch tmp/restart.txt
```

#### **C. Testar em STAGING**
```
🌐 Acessar: https://staging.seudominio.com.br
✅ Validar todas as funcionalidades
✅ Testar com dados de teste
✅ Cliente pode aprovar as mudanças
```

---

### **FASE 3: Deploy para PRODUÇÃO**

**⚠️ IMPORTANTE: Só fazer deploy para produção após aprovação em STAGING!**

#### **A. Fazer merge para main/master**
```powershell
# Merge na branch principal
git checkout main
git merge staging
git tag -a v1.2.3 -m "Release com funcionalidade X"
git push origin main --tags
```

#### **B. No servidor de PRODUÇÃO:**

```bash
# 1. BACKUP DO BANCO (OBRIGATÓRIO!)
mysqldump -u root -p sistema_insta_solutions_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Conectar ao servidor
ssh usuario@servidor-producao

# 3. Ir para a pasta do projeto
cd /var/www/sistema-insta-solutions

# 4. Baixar as mudanças
git pull origin main

# 5. Instalar dependências
bundle install --deployment --without development test

# 6. Executar migrations
RAILS_ENV=production bundle exec rails db:migrate

# 7. Recompilar assets
RAILS_ENV=production bundle exec rails assets:precompile

# 8. Reiniciar o servidor
sudo systemctl restart puma
# OU: touch tmp/restart.txt
```

#### **C. Validar em PRODUÇÃO**
```
🌐 Acessar: https://seudominio.com.br
✅ Validar funcionalidades críticas
✅ Monitorar logs: tail -f log/production.log
✅ Verificar se não há erros
```

---

## 📝 **COMANDOS ÚTEIS POR AMBIENTE**

### **Development (Local)**
```powershell
# Iniciar servidor
rails server

# Console
rails console

# Migrations
rails db:migrate
rails db:rollback

# Seeds
rails db:seed
```

### **Staging (Teste)**
```bash
# Iniciar servidor
RAILS_ENV=staging bundle exec rails server -p 3001

# Console
RAILS_ENV=staging bundle exec rails console

# Migrations
RAILS_ENV=staging bundle exec rails db:migrate

# Ver logs
tail -f log/staging.log
```

### **Production (Produção)**
```bash
# Console (somente leitura recomendado)
RAILS_ENV=production bundle exec rails console --sandbox

# Migrations
RAILS_ENV=production bundle exec rails db:migrate

# Ver logs
tail -f log/production.log

# Verificar status
sudo systemctl status puma
```

---

## 🔒 **BOAS PRÁTICAS DE SEGURANÇA**

### **1. Variáveis de Ambiente**
- ❌ **NUNCA** commitar `config/application.yml`
- ✅ Usar variáveis de ambiente diferentes para cada servidor
- ✅ Senhas fortes em produção

### **2. Backups**
- ✅ **SEMPRE** fazer backup antes de deploy em produção
- ✅ Testar restauração de backups regularmente
- ✅ Manter backups dos últimos 30 dias

### **3. Git**
```
development → staging → main/master
    ↓            ↓           ↓
  (local)     (teste)   (produção)
```

### **4. Rollback (Reverter Deploy)**
```bash
# Se algo der errado em produção:

# Opção 1: Voltar commit
git revert HEAD
git push origin main

# Opção 2: Voltar para versão anterior
git checkout v1.2.2
RAILS_ENV=production bundle exec rails db:migrate:down VERSION=20260120163843

# Opção 3: Restaurar backup
mysql -u root -p sistema_insta_solutions_production < backup_20260122_143000.sql
```

---

## 📊 **CHECKLIST DE DEPLOY**

### **Para STAGING:**
- [ ] Branch staging atualizada
- [ ] Migrations testadas localmente
- [ ] Dependências instaladas
- [ ] Assets recompilados
- [ ] Servidor reiniciado
- [ ] Testes de funcionalidade OK

### **Para PRODUÇÃO:**
- [ ] ✅ Aprovado em STAGING
- [ ] ✅ Backup do banco feito
- [ ] ✅ Tag de versão criada
- [ ] ✅ Dependências instaladas
- [ ] ✅ Migrations executadas
- [ ] ✅ Assets recompilados
- [ ] ✅ Servidor reiniciado
- [ ] ✅ Validação pós-deploy OK
- [ ] ✅ Logs monitorados (15 min)

---

## 🆘 **TROUBLESHOOTING**

### **Erro: "PG::ConnectionBad" ou "Mysql2::Error"**
```bash
# Verificar se o banco está rodando
sudo systemctl status mysql

# Verificar variáveis de ambiente
RAILS_ENV=staging bundle exec rails runner "puts ActiveRecord::Base.connection_config"
```

### **Erro: "Assets não encontrados"**
```bash
# Recompilar assets
RAILS_ENV=production bundle exec rails assets:clobber
RAILS_ENV=production bundle exec rails assets:precompile
```

### **Erro: "Migration pendente"**
```bash
# Ver status das migrations
RAILS_ENV=production bundle exec rails db:migrate:status

# Executar migrations pendentes
RAILS_ENV=production bundle exec rails db:migrate
```

---

## 📞 **SUPORTE**

Se tiver dúvidas ou problemas:
1. Verificar logs: `tail -f log/[ambiente].log`
2. Verificar configuração: `config/application.yml`
3. Consultar esta documentação
4. Contatar a equipe de desenvolvimento

---

**Documentação criada por:** GitHub Copilot  
**Data:** 22/01/2026  
**Versão:** 1.0
