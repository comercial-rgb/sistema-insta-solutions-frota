# PREVENÇÃO DE INCONSISTÊNCIAS DE STATUS - Sistema Frota Insta Solutions

**Data da implementação:** 31/01/2026

## 🔴 PROBLEMA IDENTIFICADO

### Causa Raiz
Os arquivos `order_service_status.rb` e `order_service_proposal_status.rb` tinham constantes com **IDs incorretos** que não correspondiam aos IDs reais do banco de dados.

**Exemplo do problema:**
```ruby
# ANTES (IDs errados):
OrderServiceStatus::APROVADA_ID = 5  # ❌ No banco real é 3
OrderServiceProposalStatus::APROVADA_ID = 14  # ❌ No banco real é 3

# Quando aprovava uma proposta:
proposta.update(status_id: 14)  # ❌ Salvava ID inexistente
os.update(status_id: 5)  # ❌ Salvava status "Autorizada" em vez de "Aprovada"
```

### Consequências
- ✗ Propostas ficavam aprovadas mas OSs travadas em "Aguardando avaliação"
- ✗ Fluxo de trabalho interrompido
- ✗ Necessidade de correção manual no banco
- ✗ Impacto no faturamento e gestão

---

## ✅ SOLUÇÕES IMPLEMENTADAS

### 1. Correção dos IDs (CRÍTICO)
**Arquivos corrigidos:**
- `app/models/order_service_status.rb`
- `app/models/order_service_proposal_status.rb`

**IDs agora correspondem ao banco real:**
```ruby
# OrderServiceStatus (CORRETO):
EM_ABERTO_ID = 1
AGUARDANDO_AVALIACAO_PROPOSTA_ID = 2
APROVADA_ID = 3
NOTA_FISCAL_INSERIDA_ID = 4
AUTORIZADA_ID = 5
AGUARDANDO_PAGAMENTO_ID = 6
PAGA_ID = 7
CANCELADA_ID = 8
EM_CADASTRO_ID = 9
EM_REAVALIACAO_ID = 10

# OrderServiceProposalStatus (CORRETO):
EM_ABERTO_ID = 1
AGUARDANDO_AVALIACAO_ID = 2
APROVADA_ID = 3
NOTAS_INSERIDAS_ID = 4
AUTORIZADA_ID = 5
AGUARDANDO_PAGAMENTO_ID = 6
PAGA_ID = 7
PROPOSTA_REPROVADA_ID = 8
CANCELADA_ID = 9
EM_CADASTRO_ID = 10
AGUARDANDO_APROVACAO_COMPLEMENTO_ID = 11
```

---

### 2. Sincronização Automática (PREVENÇÃO)
**Arquivo:** `app/models/order_service_proposal.rb`

**Implementação de callback automático:**
```ruby
after_update :sync_order_service_status, if: :saved_change_to_order_service_proposal_status_id?

def sync_order_service_status
  # Mapeamento automático: Status da Proposta → Status da OS
  status_mapping = {
    APROVADA_ID => APROVADA_ID,
    NOTAS_INSERIDAS_ID => NOTA_FISCAL_INSERIDA_ID,
    AUTORIZADA_ID => AUTORIZADA_ID,
    AGUARDANDO_PAGAMENTO_ID => AGUARDANDO_PAGAMENTO_ID,
    PAGA_ID => PAGA_ID
  }
  
  # Atualiza automaticamente o status da OS quando a proposta mudar
  # Gera histórico automaticamente
end
```

**Como funciona:**
- ✓ Quando uma proposta muda de status, a OS é automaticamente atualizada
- ✓ Não depende mais do controller fazer a atualização manualmente
- ✓ Funciona em qualquer parte do sistema (interface, API, console)
- ✓ Gera histórico automaticamente para auditoria
- ✓ Ignora complementos (não alteram status da OS principal)

---

### 3. Script de Correção em Massa
**Arquivo:** `fix_all_inconsistencies.rb`

**Funcionalidades:**
- ✓ Busca todas as OSs com status inconsistente
- ✓ Corrige automaticamente baseado no status da proposta aprovada
- ✓ Gera histórico para cada correção
- ✓ Relatório detalhado com contadores e erros
- ✓ Seguro: não afeta OSs já corretas

**Execução:**
```bash
cd /var/www/frotainstasolutions/production
RAILS_ENV=production bundle exec rails runner /tmp/fix_all_inconsistencies.rb
```

---

## 🛡️ COMO ISSO PREVINE PROBLEMAS FUTUROS

### Antes (Sistema Vulnerável):
```
Gestor aprova proposta
    ↓
Controller tenta atualizar OS com ID errado
    ↓
OS fica com status incorreto
    ↓
❌ PROBLEMA: Inconsistência
```

### Agora (Sistema Protegido):
```
Gestor aprova proposta
    ↓
Proposta muda para "Aprovada" (ID 3)
    ↓
Callback automático detecta mudança
    ↓
OS automaticamente atualizada para "Aprovada" (ID 3)
    ↓
Histórico gerado automaticamente
    ↓
✅ SUCESSO: Sempre sincronizado!
```

---

## 📊 VALIDAÇÃO DA CORREÇÃO

**Teste realizado em 31/01/2026:**
- ✓ OS6805722026112 corrigida (estava travada, agora aprovada)
- ✓ Todas as OSs do sistema verificadas: 0 inconsistências
- ✓ Callback testado e funcionando
- ✓ Servidor reiniciado com sucesso

---

## 🔧 MANUTENÇÃO FUTURA

### Se ocorrer uma inconsistência novamente:
1. **Investigar a causa:** O callback não deveria permitir isso
2. **Executar script de correção:** `fix_all_inconsistencies.rb`
3. **Verificar logs:** Buscar mensagens de erro no Rails.logger

### Monitoramento recomendado:
- Verificar periodicamente se há OSs com proposta aprovada mas status diferente
- Query SQL para monitoramento:
```sql
SELECT os.code, os.order_service_status_id, osp.order_service_proposal_status_id
FROM order_services os
JOIN order_service_proposals osp ON osp.order_service_id = os.id
WHERE osp.order_service_proposal_status_id = 3
  AND os.order_service_status_id != 3;
```

---

## 📝 RESUMO EXECUTIVO

**Problema:** IDs incorretos causando inconsistências de status  
**Causa:** Dessincronia entre constantes do código e IDs do banco  
**Solução:** Correção dos IDs + callback automático de sincronização  
**Status:** ✅ RESOLVIDO E PREVENIDO  
**Impacto:** Zero inconsistências no sistema após implementação  

**Deploy realizado:** 31/01/2026 15:32 UTC  
**Servidor:** frotainstasolutions (Puma 6.6.0)  
**Verificação:** Todas as OSs sincronizadas corretamente
