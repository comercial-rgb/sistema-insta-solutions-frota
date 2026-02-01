# 🔄 Plano de Migração: Repositório → Nova Produção

## ⚠️ IMPORTANTE: Leia completamente antes de executar

Este documento descreve como tornar este repositório a nova produção, substituindo o sistema atual.

---

## 📊 Análise da Situação

### Cenário Atual
```
┌─────────────────────┐         ┌──────────────────────┐
│  Produção Antiga    │         │  Repositório Novo    │
│  (em uso)           │         │  (este repo)         │
├─────────────────────┤         ├──────────────────────┤
│ - Banco desatualizado│         │ - Código corrigido   │
│ - IDs incorretos    │         │ - IDs sincronizados  │
│ - Encoding com ???? │         │ - UTF-8 correto      │
│ - Badges bugados    │         │ - Badges funcionando │
│ - Cálculos errados  │         │ - Cálculos corretos  │
└─────────────────────┘         └──────────────────────┘
```

### O que queremos
```
┌────────────────────────────────────┐
│     Nova Produção (este repo)      │
│  Com dados da produção atual       │
├────────────────────────────────────┤
│ ✅ Código corrigido                │
│ ✅ Dados atualizados               │
│ ✅ Estrutura sincronizada          │
└────────────────────────────────────┘
```

---

## 🎯 Estratégia: Migração Progressiva

### Fase 1: Auditoria (SEM RISCO)

**Objetivo**: Entender diferenças entre produção atual e este repo

```powershell
# 1. Obter dump ATUAL da produção (não o antigo de janeiro)
# Solicitar ao responsável pelo banco de produção:
mysqldump -u [user] -p [database_name] > prod_atual_$(date +%Y%m%d).sql

# 2. Importar em banco SEPARADO para análise
mysql -u root -p -e "CREATE DATABASE prod_atual_analise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -pprod_atual_analise < prod_atual_YYYYMMDD.sql

# 3. Comparar estruturas
```

**Script de comparação**:

```ruby
# scripts/compare_production_schema.rb
require 'diffy'

# Conectar aos dois bancos
ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  host: 'localhost',
  username: 'root',
  password: 'rot123',
  database: 'sistema_insta_solutions_development'
)

prod_connection = ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  host: 'localhost',
  username: 'root',
  password: 'rot123',
  database: 'prod_atual_analise'
).connection

puts "=" * 60
puts "COMPARAÇÃO: Desenvolvimento vs Produção Atual"
puts "=" * 60

# Comparar tabelas
dev_tables = ActiveRecord::Base.connection.tables.sort
prod_tables = prod_connection.tables.sort

puts "\n[TABELAS]"
puts "  Só no DEV: #{(dev_tables - prod_tables).join(', ')}"
puts "  Só na PROD: #{(prod_tables - dev_tables).join(', ')}"

# Comparar colunas das tabelas principais
critical_tables = [
  'order_services',
  'order_service_proposals', 
  'order_service_statuses',
  'order_service_proposal_statuses',
  'users',
  'vehicles',
  'vehicle_models'
]

critical_tables.each do |table|
  next unless dev_tables.include?(table) && prod_tables.include?(table)
  
  dev_cols = ActiveRecord::Base.connection.columns(table).map(&:name).sort
  prod_cols = prod_connection.columns(table).map(&:name).sort
  
  if dev_cols != prod_cols
    puts "\n[#{table.upcase}]"
    puts "  Colunas só no DEV: #{(dev_cols - prod_cols).join(', ')}"
    puts "  Colunas só na PROD: #{(prod_cols - dev_cols).join(', ')}"
  end
end

# Comparar IDs de status
puts "\n[STATUS IDs - CRÍTICO]"

dev_os_statuses = ActiveRecord::Base.connection.select_all(
  "SELECT id, name FROM order_service_statuses ORDER BY id"
).to_a

prod_os_statuses = prod_connection.select_all(
  "SELECT id, name FROM order_service_statuses ORDER BY id"
).to_a

puts "\nOrderServiceStatus:"
puts "DEV:  #{dev_os_statuses.map { |s| "#{s['id']}=#{s['name']}" }.join(', ')}"
puts "PROD: #{prod_os_statuses.map { |s| "#{s['id']}=#{s['name']}" }.join(', ')}"

# Comparar contadores
puts "\n[CONTADORES]"
puts "Tabela                         | DEV      | PROD     | Diff"
puts "-" * 60

critical_tables.each do |table|
  next unless dev_tables.include?(table) && prod_tables.include?(table)
  
  dev_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table}")
  prod_count = prod_connection.select_value("SELECT COUNT(*) FROM #{table}")
  diff = prod_count - dev_count
  
  printf "%-30s | %-8d | %-8d | %+d\n", table, dev_count, prod_count, diff
end

puts "\n" + "=" * 60
puts "RESULTADO: #{prod_tables.size} tabelas na produção"
puts "=" * 60
```

### Fase 2: Decisão baseada na auditoria

#### Cenário A: Produção tem MESMA estrutura

**Ação**: Apenas aplicar scripts de correção no banco de produção

```powershell
# Conectar direto na produção
mysql -h [prod_host] -u [prod_user] -p [prod_db] < scripts/fix_production.sql

# Ou via Rails (mais seguro)
RAILS_ENV=production bundle exec rails runner scripts/sync_status_ids.rb
RAILS_ENV=production bundle exec rails runner scripts/fix_users_encoding.rb
```

#### Cenário B: Produção tem estrutura DIFERENTE

**Ação**: Criar migrações para alinhar produção ao código

```ruby
# db/migrate/YYYYMMDDHHMMSS_align_production_schema.rb
class AlignProductionSchema < ActiveRecord::Migration[7.1]
  def up
    # Adicionar colunas faltantes
    unless column_exists?(:order_services, :is_complement)
      add_column :order_services, :is_complement, :boolean, default: false
    end
    
    unless column_exists?(:order_services, :parent_proposal_id)
      add_column :order_services, :parent_proposal_id, :bigint
    end
    
    # ... outras correções baseadas na auditoria
  end
  
  def down
    remove_column :order_services, :is_complement if column_exists?(:order_services, :is_complement)
    remove_column :order_services, :parent_proposal_id if column_exists?(:order_services, :parent_proposal_id)
  end
end
```

---

## 🚀 Fase 3: Migração com Zero Downtime

### Opção 3A: Blue-Green Deployment (IDEAL)

**Passos:**

1. **Setup Green (novo ambiente)**
   ```bash
   # Na AWS: criar nova EC2 + RDS
   # Instalar aplicação deste repositório
   # Importar dump produção + aplicar correções
   ```

2. **Período de testes paralelos (1-2 semanas)**
   ```
   Usuários Teste → Green (novo)
   Usuários Produção → Blue (antigo)
   ```

3. **Sincronização de dados**
   ```bash
   # Diariamente: copiar dados do Blue → Green
   # Testar se correções funcionam com dados reais
   ```

4. **Cutover (troca)**
   ```bash
   # Em horário de baixo uso:
   # 1. Bloquear escrita no Blue
   # 2. Última sincronização Blue → Green
   # 3. Trocar DNS/Load Balancer para Green
   # 4. Monitorar
   # 5. Se problema: voltar para Blue
   ```

### Opção 3B: Migração In-Place (MAIS RÁPIDO)

**Passos:**

1. **Backup completo produção**
   ```bash
   mysqldump --single-transaction [prod_db] > backup_pre_migration.sql
   ```

2. **Janela de manutenção (4-6 horas, madrugada)**
   ```
   22:00 - Anúncio: "Sistema em manutenção às 02:00"
   02:00 - Colocar sistema em modo manutenção
   02:10 - Fazer deploy código novo
   02:20 - Executar migrações + scripts correção
   02:40 - Testes smoke
   03:00 - Reativar sistema
   03:00-06:00 - Monitoramento intensivo
   ```

3. **Script de migração all-in-one**
   ```bash
   #!/bin/bash
   # deploy-and-fix-production.sh
   
   set -e
   
   echo "🔒 Ativando modo manutenção..."
   touch public/maintenance.html
   
   echo "💾 Backup..."
   mysqldump [prod_db] > backup_$(date +%Y%m%d_%H%M%S).sql
   
   echo "📦 Deploy código..."
   git pull origin main
   bundle install
   
   echo "🔧 Migrações..."
   RAILS_ENV=production rails db:migrate
   
   echo "✨ Correções..."
   RAILS_ENV=production rails runner scripts/sync_status_ids.rb
   RAILS_ENV=production rails runner scripts/fix_users_encoding.rb
   RAILS_ENV=production rails runner scripts/add_os_complement_columns.rb
   
   echo "🎨 Assets..."
   RAILS_ENV=production rails assets:precompile
   
   echo "🔄 Restart..."
   sudo systemctl restart puma
   sudo systemctl restart nginx
   
   echo "✅ Remover modo manutenção..."
   rm public/maintenance.html
   
   echo "🎉 MIGRAÇÃO CONCLUÍDA!"
   ```

---

## ✅ Recomendação Final

**CENÁRIO IDEAL** (se tiver acesso AWS):
1. ✅ Executar Fase 1 (auditoria) - **HOJE**
2. ✅ Criar ambiente staging com dump produção real - **AMANHÃ**
3. ✅ Testar correções com dados reais por 3-5 dias
4. ✅ Blue-Green deployment para produção - **SEMANA QUE VEM**

**CENÁRIO REALISTA** (sem AWS por enquanto):
1. ✅ Executar Fase 1 (auditoria) - **HOJE**
2. ✅ Solicitar dump produção ATUAL ao responsável
3. ✅ Testar restauração + correções localmente
4. ✅ Agendar janela de manutenção com cliente
5. ✅ Migração in-place com backup

---

## 📋 Checklist Pré-Migração

Antes de tocar na produção:

- [ ] Auditoria completa executada
- [ ] Diferenças documentadas
- [ ] Testes com dados reais realizados
- [ ] Backup completo da produção criado
- [ ] Backup testado (consegue restaurar)
- [ ] Plano de rollback definido
- [ ] Cliente/usuários avisados
- [ ] Equipe de plantão escalada
- [ ] Horário de baixo uso escolhido
- [ ] Monitoramento preparado

---

## 🆘 Plano de Rollback

Se algo der errado após migração:

```bash
# 1. Voltar código
git reset --hard [commit-anterior]
bundle install
RAILS_ENV=production rails assets:precompile
sudo systemctl restart puma

# 2. Restaurar banco (SE NECESSÁRIO)
mysql [prod_db] < backup_pre_migration.sql

# 3. Validar
curl http://localhost/health_check
```

---

## 📞 Contatos de Emergência

- Responsável Banco: [NOME] - [TELEFONE]
- DevOps: [NOME] - [TELEFONE]
- Cliente: [NOME] - [TELEFONE]

---

**Criado em**: 2026-01-22  
**Revisão necessária após**: Auditoria Fase 1
