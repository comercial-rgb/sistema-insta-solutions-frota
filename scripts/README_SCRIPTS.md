# 📂 Guia de Scripts - Sistema Insta Solutions

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Scripts por Categoria](#scripts-por-categoria)
- [Como Usar](#como-usar)
- [Cenários Comuns](#cenários-comuns)

---

## 🎯 Visão Geral

Esta pasta contém **68 scripts** criados durante o processo de correção do banco de dados do cliente. Eles estão organizados em 3 categorias principais:

### ⚠️ IMPORTANTE
- **NÃO execute scripts aleatoriamente!**
- **Sempre faça backup do banco antes de executar correções**
- **Muitos scripts são pontuais e JÁ FORAM EXECUTADOS**

---

## 📁 Scripts por Categoria

### 🔴 1. Scripts de Correção PONTUAIS (Não executar novamente)

Esses scripts corrigiram problemas **específicos** do banco recebido em 26/01/2026:

#### **Encoding UTF-8 Corrompido:**
- `fix_encoding_comprehensive.rb` ✅ Executado - corrigiu 149 users + 275 services
- `fix_all_remaining_encoding.rb` ✅ Executado - corrigiu provider_service_types, contracts
- `fix_users_encoding.rb`, `fix_services_and_items_encoding.rb`
- `fix_categories_services_encoding.rb`, `fix_cities_encoding.rb`
- `fix_encoding_data.rb`, `fix_encoding_v2.rb`, `fix_encoding_manual.rb`
- E mais ~20 variações de scripts de encoding

**Status:** ✅ Problemas corrigidos. Encoding está OK no banco atual.

#### **Datas Erradas (2026 → 2025):**
- `fix_all_dates_2026_to_2025.rb` - Corrigiu datas de janeiro
- `restore_legitimate_2026_data.rb` - Restaurou dados legítimos de 2026
- `fix_audit_dates_2026_to_2025.rb` - Corrigiu audits

**Status:** ⚠️ Específico para dados importados com ano errado. Não aplicável ao banco atual.

#### **Colunas Faltantes:**
- `add_os_complement_columns.rb` - Adicionou is_complement, justification, etc.
- `add_refused_approval_columns.rb` - Adicionou reason_refused_approval

**Status:** ✅ Colunas já adicionadas manualmente via SQL.

---

### 🟡 2. Scripts de Verificação/Auditoria (Seguros - apenas leitura)

Scripts que **NÃO modificam** o banco, apenas mostram informações:

#### **Verificação de Encoding:**
- `check_encoding.rb` - Verifica problemas de encoding em todas as tabelas
- `audit_all_encoding.rb` - Auditoria completa de encoding
- `find_encoding_issues.rb` - Encontra registros com problemas
- `analyze_encoding_detailed.rb` - Análise detalhada
- `comprehensive_check.rb` - Verificação abrangente
- `final_verification.rb` - Verificação final

#### **Listagem de Dados:**
- `list_os_statuses.rb` - Lista todos os status de OS
- `list_os_types.rb` - Lista tipos de OS
- `list_proposal_statuses.rb` - Lista status de propostas
- `list_proposal_columns.rb` - Lista colunas de propostas
- `show_remaining.rb` - Mostra problemas restantes
- `show_services_data.rb` - Mostra dados de serviços

#### **Verificação de Estrutura:**
- `check_missing_migrations.rb` - Verifica migrações pendentes
- `check_os_66.rb` - Verifica OS específica
- `check_commitments_cost_centers_contracts.rb` - Verifica relacionamentos

**Como usar:**
```powershell
bundle exec rails runner scripts/check_encoding.rb
bundle exec rails runner scripts/list_os_statuses.rb
```

---

### 🟢 3. Scripts Operacionais (Úteis no futuro)

Scripts que podem ser executados conforme necessário:

- `populate_vehicle_models.rb` - Popular tabela de modelos de veículos
- `create_reference_prices_table.rb` - Criar tabela de preços de referência
- `create_image_placeholders.rb` - Criar placeholders para imagens
- `backup-frotainstasolutions.sh` - Script de backup para servidor Linux (EC2)

**Como usar:**
```powershell
bundle exec rails runner scripts/populate_vehicle_models.rb
```

---

## ⭐ Script Consolidado Recomendado

### `fix_new_client_database.rb` (NOVO - Criado hoje)

**Propósito:** Script ÚNICO que aplica TODAS as correções necessárias quando receber um novo banco do cliente.

**Funcionalidades:**
1. ✅ Adiciona colunas faltantes (9 colunas em 5 tabelas)
2. ✅ Corrige encoding UTF-8 em 9 tabelas diferentes
3. ✅ Verifica existência dos 11 status obrigatórios
4. ✅ Gera relatório completo de correções
5. ✅ Suporta modo de simulação (DRY_RUN)

**Como usar:**

```powershell
# 1. MODO DE SIMULAÇÃO (não modifica nada, apenas mostra o que faria)
# Edite o arquivo e defina: DRY_RUN = true
bundle exec rails runner scripts/fix_new_client_database.rb

# 2. EXECUTAR CORREÇÕES DE VERDADE
# Edite o arquivo e defina: DRY_RUN = false
bundle exec rails runner scripts/fix_new_client_database.rb
```

**Quando usar:**
- ✅ Recebeu novo backup do cliente
- ✅ Banco tem caracteres `????` ou `Ã§Ã£`
- ✅ Faltam colunas de complemento/aprovação
- ✅ Status com IDs faltando

---

## 🎯 Cenários Comuns

### Cenário 1: "Recebi um novo banco do cliente"

```powershell
# 1. Fazer backup do banco atual
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" `
  -u root -prot123 sistema_insta_solutions_development `
  > "backup_antes_importacao_$timestamp.sql"

# 2. Importar novo banco do cliente
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" `
  -u root -prot123 sistema_insta_solutions_development `
  < "banco_cliente_novo.sql"

# 3. Rodar migrações (estrutura)
bundle exec rails db:migrate

# 4. TESTAR em modo simulação primeiro
# Editar scripts/fix_new_client_database.rb: DRY_RUN = true
bundle exec rails runner scripts/fix_new_client_database.rb

# 5. Se tudo OK, aplicar correções
# Editar scripts/fix_new_client_database.rb: DRY_RUN = false
bundle exec rails runner scripts/fix_new_client_database.rb

# 6. Reiniciar servidor e testar
.\restart-clear.ps1
```

### Cenário 2: "Quero verificar se há problemas de encoding"

```powershell
# Script de verificação (não modifica nada)
bundle exec rails runner scripts/check_encoding.rb

# Ou auditoria completa
bundle exec rails runner scripts/audit_all_encoding.rb
```

### Cenário 3: "Preciso listar todos os status"

```powershell
bundle exec rails runner scripts/list_os_statuses.rb
bundle exec rails runner scripts/list_proposal_statuses.rb
```

### Cenário 4: "Banco de produção funcionando - preciso executar algo?"

**Resposta: NÃO!**

O banco que você vai subir hoje para produção já tem:
- ✅ Todas as 89 migrações aplicadas
- ✅ Encoding corrigido (424+ registros)
- ✅ 11 status corretos (IDs 1-11)
- ✅ Colunas de complemento/aprovação
- ✅ Constantes do Rails corrigidas

**Não execute nenhum script em produção!**

---

## 🚨 Avisos Importantes

### ⚠️ Antes de Executar Qualquer Script:

1. **SEMPRE faça backup do banco:**
   ```powershell
   $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
   & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" `
     -u root -prot123 sistema_insta_solutions_development `
     > "backup_pre_script_$timestamp.sql"
   ```

2. **Leia o código do script** antes de executar
3. **Teste em desenvolvimento** antes de produção
4. **Use modo DRY_RUN** quando disponível

### ❌ Scripts que NÃO devem ser executados novamente:

Todos os scripts de correção pontual já foram executados:
- `fix_encoding_comprehensive.rb`
- `fix_all_remaining_encoding.rb`
- `fix_all_dates_2026_to_2025.rb`
- `add_os_complement_columns.rb`
- E todos os outros `fix_*` específicos

**Por quê?** Porque essas correções já estão aplicadas no banco atual.

---

## 📝 Resumo Executivo

| Situação | Ação Recomendada |
|----------|------------------|
| **Banco atual em produção** | ❌ Nada - está correto |
| **Novo banco do cliente** | ✅ Executar `fix_new_client_database.rb` |
| **Verificar problemas** | ✅ Executar scripts `check_*` ou `list_*` |
| **Backup/Restore** | ✅ Usar comandos mysqldump/mysql |
| **Dúvidas sobre status** | ✅ Executar `list_os_statuses.rb` |

---

## 🔧 Manutenção

### Atualizar Script Consolidado

Se surgirem novos problemas recorrentes, adicione as correções em:
- `scripts/fix_new_client_database.rb`

### Limpar Scripts Antigos

Considere mover scripts obsoletos para pasta `scripts/archive/`:
- Scripts de correção pontual já executados
- Scripts de testes/investigação temporários

---

## 📞 Suporte

Se tiver dúvidas sobre qual script executar:
1. Verifique este README primeiro
2. Leia o cabeçalho do script (comentários no início)
3. Execute em modo DRY_RUN se disponível
4. Faça backup antes de qualquer modificação

---

**Última atualização:** 26/01/2026
**Banco atual:** Corrigido e pronto para produção ✅
