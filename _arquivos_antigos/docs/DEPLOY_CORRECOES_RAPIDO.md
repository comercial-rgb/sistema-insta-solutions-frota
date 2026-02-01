# 🚀 DEPLOY RÁPIDO DAS CORREÇÕES - AWS

## ⚡ Deploy em 5 Minutos

### 📋 Pré-requisitos
- Acesso SSH ao servidor AWS
- IP do servidor AWS
- Usuário do servidor (geralmente `ubuntu` ou `ec2-user`)

---

## 🎯 OPÇÃO 1: Deploy Automatizado (Recomendado)

### Passo 1: Executar script de deploy
```powershell
# No seu computador local (Windows)
.\deploy-correcoes-aws.ps1 -ServerIP "SEU_IP_AQUI"

# Exemplo:
.\deploy-correcoes-aws.ps1 -ServerIP "200.100.50.25"
```

O script irá:
1. ✅ Criar pacote com as correções
2. ✅ Mostrar instruções de deploy
3. ✅ Preparar comandos de backup e rollback

---

## 🎯 OPÇÃO 2: Deploy Manual (Passo a Passo)

### 1️⃣ Criar Pacote Local
```powershell
# Criar pacote com todas as correções
tar -czf correcoes-os-fix.tar.gz `
  app/grids/order_service_proposals_grid.rb `
  app/grids/order_services_grid.rb `
  app/views/order_service_proposals/*.html.erb `
  app/views/order_services/*.html.erb `
  app/views/order_services/_*.html.erb `
  check_production_status.rb `
  validate_fixes.rb `
  CORRECOES_APLICADAS.md
```

### 2️⃣ Conectar ao Servidor
```bash
# Substitua pelo IP do seu servidor
ssh ubuntu@200.100.50.25

# OU se for ec2-user
ssh ec2-user@200.100.50.25
```

### 3️⃣ Fazer Backup no Servidor
```bash
cd /var/www/frotainstasolutions

# Criar diretório de backups
mkdir -p backups

# Fazer backup dos arquivos que serão alterados
tar -czf backups/backup_antes_correcoes_$(date +%Y-%m-%d_%H-%M).tar.gz \
  app/grids/order_service_proposals_grid.rb \
  app/grids/order_services_grid.rb \
  app/views/order_service_proposals/ \
  app/views/order_services/

echo "✅ Backup criado!"
```

### 4️⃣ Enviar Pacote (do seu computador)
```powershell
# No PowerShell do seu computador
scp correcoes-os-fix.tar.gz ubuntu@200.100.50.25:/tmp/

# OU
scp correcoes-os-fix.tar.gz ec2-user@200.100.50.25:/tmp/
```

### 5️⃣ Extrair no Servidor
```bash
# Voltar para o SSH do servidor
cd /var/www/frotainstasolutions

# Extrair correções
tar -xzf /tmp/correcoes-os-fix.tar.gz

# Verificar permissões
chown -R ubuntu:ubuntu app/
# OU
chown -R ec2-user:ec2-user app/

echo "✅ Arquivos extraídos!"
```

### 6️⃣ Validar Correções
```bash
cd /var/www/frotainstasolutions

# Executar script de validação
RAILS_ENV=production bundle exec rails runner check_production_status.rb
```

### 7️⃣ Reiniciar Servidor
```bash
# Descobrir qual serviço está rodando
sudo systemctl list-units --type=service | grep -i puma

# Opção 1: Reiniciar Puma
sudo systemctl restart puma_frotainstasolutions

# Opção 2: Se o serviço tiver outro nome
sudo systemctl restart frotainstasolutions

# Opção 3: Usando Capistrano (se configurado)
bundle exec cap production deploy:restart

# Verificar status
sudo systemctl status puma_frotainstasolutions
```

### 8️⃣ Verificar Logs
```bash
# Ver logs em tempo real
tail -f /var/www/frotainstasolutions/log/production.log

# Ver últimas 100 linhas
tail -n 100 /var/www/frotainstasolutions/log/production.log

# Verificar se há erros
grep -i "error" /var/www/frotainstasolutions/log/production.log | tail -20
```

### 9️⃣ Testar no Browser
1. Acesse: https://app.frotainstasolutions.com.br
2. Faça login como Admin
3. Teste os 3 cenários:
   - ✅ Editar OS e ver botão de salvar
   - ✅ Visualizar OS "Aguardando Avaliação"
   - ✅ Fornecedor acessar suas OS

---

## 🔄 ROLLBACK (se necessário)

### Se algo der errado, restaurar backup:

```bash
cd /var/www/frotainstasolutions

# Listar backups disponíveis
ls -lh backups/

# Restaurar último backup
tar -xzf backups/backup_antes_correcoes_YYYY-MM-DD_HH-MM.tar.gz

# Reiniciar servidor
sudo systemctl restart puma_frotainstasolutions

echo "✅ Rollback concluído!"
```

---

## 📊 CHECKLIST DE VALIDAÇÃO

Após o deploy, verificar:

- [ ] Sistema carregou sem erros
- [ ] Login funciona normalmente
- [ ] Admin consegue editar OS e VÊ botão de salvar
- [ ] Gestor consegue editar OS e VÊ botão de salvar
- [ ] Adicional consegue editar OS e VÊ botão de salvar
- [ ] Aba "Aguardando Avaliação" NÃO dá erro 500
- [ ] Fornecedores conseguem acessar suas OS
- [ ] Visualização de OS não dá erro 500
- [ ] Logs sem erros críticos

---

## 🆘 TROUBLESHOOTING

### Problema: Erro de permissão
```bash
sudo chown -R ubuntu:ubuntu /var/www/frotainstasolutions
# OU
sudo chown -R ec2-user:ec2-user /var/www/frotainstasolutions
```

### Problema: Servidor não reinicia
```bash
# Ver logs do systemd
sudo journalctl -u puma_frotainstasolutions -n 50

# Tentar start ao invés de restart
sudo systemctl start puma_frotainstasolutions
```

### Problema: Ainda dá erro 500
```bash
# Verificar IDs no banco
cd /var/www/frotainstasolutions
RAILS_ENV=production bundle exec rails runner check_production_status.rb

# Verificar logs de erro
tail -100 log/production.log | grep -i "error\|exception"
```

---

## 📞 SUPORTE

Se precisar de ajuda:
1. Verifique os logs: `tail -f log/production.log`
2. Execute o diagnóstico: `rails runner check_production_status.rb`
3. Faça rollback se necessário (instruções acima)

---

## ✅ CORREÇÕES APLICADAS

1. **Botão de salvar para Admin/Gestor/Adicional**
   - Admin agora pode salvar edições de OS
   
2. **Erro 500 em visualização de OS**
   - Safe navigation protege contra status NULL
   - 15 arquivos corrigidos (views + grids)
   
3. **Fornecedores acessando OS**
   - Sem mais erro 500 ao acessar

---

**Data:** 27/01/2026  
**Versão:** 1.0  
**Testado:** ✅ Sim
