# Análise: OS6657512026128 com Duas Propostas Ativas

**Data:** 02/02/2026  
**OS:** OS6657512026128  
**Propostas:**
- P787OS6657512026128 - Status: **AUTORIZADA** (ID 16)
- P834OS6657512026128 - Status: **NOTAS FISCAIS INSERIDAS** (ID 15)

---

## 🔴 PROBLEMA IDENTIFICADO

### Cenário Relatado
A equipe de suporte alterou itens da OS (mudou "lavagem" de peça para serviço), mas a alteração não refletiu automaticamente no sistema do fornecedor. Como solução:

1. Enviaram a primeira proposta errada (P787)
2. **CANCELARAM** a proposta P787
3. O fornecedor preencheu novamente e criou P834
4. P834 foi aprovada e seguiu o fluxo normal

### Problema Detectado
**A proposta P787 não está como CANCELADA (ID 20), mas sim como AUTORIZADA (ID 16)!**

Isso significa que:
- ❌ Existe uma OS com DUAS propostas em status ativos diferentes
- ❌ P787 foi AUTORIZADA em algum momento (não foi apenas cancelada)
- ❌ P834 também foi aprovada e está em NOTAS FISCAIS INSERIDAS

---

## 🔍 ANÁLISE DO CÓDIGO

### 1. Status das Propostas (OrderServiceProposalStatus)

```ruby
EM_CADASTRO_ID = 1                          # Proposta em criação
AGUARDANDO_AVALIACAO_ID = 13               # Aguardando cliente avaliar
APROVADA_ID = 14                            # Aprovada pelo cliente
NOTAS_INSERIDAS_ID = 15                     # Fornecedor inseriu notas fiscais
AUTORIZADA_ID = 16                          # ⚠️ AUTORIZADA (consumo confirmado)
AGUARDANDO_PAGAMENTO_ID = 17               # Aguardando pagamento
PAGA_ID = 18                                # Paga
PROPOSTA_REPROVADA_ID = 19                 # Reprovada
CANCELADA_ID = 20                           # Cancelada
```

**Status Críticos** (consomem recursos do cliente):
```ruby
REQUIRED_PROPOSAL_STATUSES = [
  APROVADA_ID,              # 14
  NOTAS_INSERIDAS_ID,       # 15
  AUTORIZADA_ID,            # 16 ⚠️
  AGUARDANDO_PAGAMENTO_ID,  # 17
  PAGA_ID                   # 18
]
```

### 2. Fluxo de Autorização

#### Código: `autorize_order_service_proposal` (linha 602)

```ruby
def autorize_order_service_proposal
  authorize @order_service_proposal
  
  if @current_user.additional?
    # Pré-autorização (usuário adicional)
    @order_service_proposal.update_columns(
      authorized_by_additional_id: @current_user.id,
      authorized_by_additional_at: DateTime.now,
      pending_manager_authorization: true
    )
  elsif @current_user.manager? || @current_user.admin?
    # AUTORIZAÇÃO FINAL (gestor/admin)
    @order_service_proposal.update_columns(
      order_service_proposal_status_id: OrderServiceProposalStatus::AUTORIZADA_ID,
      pending_manager_authorization: false
    )
    
    # ⚠️ ATUALIZA A OS PARA AUTORIZADA
    @order_service_proposal.order_service.update_columns(
      order_service_status_id: OrderServiceStatus::AUTORIZADA_ID
    )
  end
end
```

### 3. Cancelamento de Proposta

#### Código: `cancel_order_service_proposal` (linha 825)

```ruby
def cancel_order_service_proposal
  authorize @order_service_proposal
  @order_service_proposal.update_columns(
    order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID
  )
  OrderServiceProposal.generate_historic(...)
  flash[:success] = "Proposta cancelada com sucesso"
end
```

**⚠️ PROBLEMA:** O cancelamento NÃO verifica se a proposta já foi autorizada!

---

## 🚨 FALHA IDENTIFICADA

### Como o Problema Ocorreu

1. **Primeira Tentativa (P787)**
   - Equipe criou proposta com itens errados
   - Proposta foi **APROVADA** (status 14)
   - Proposta foi **AUTORIZADA** (status 16) ← **CONSUMIU SALDO**
   - OS ficou em status AUTORIZADA

2. **"Cancelamento" Manual**
   - Equipe tentou cancelar P787
   - Se usaram o método `cancel_order_service_proposal`, apenas mudou status
   - **MAS**: O saldo já foi consumido!

3. **Segunda Proposta (P834)**
   - Fornecedor criou nova proposta com itens corretos
   - Cliente APROVOU novamente (status 14)
   - Fornecedor inseriu notas fiscais (status 15)
   - **PODE TER CONSUMIDO SALDO NOVAMENTE**

### Vulnerabilidades no Sistema

#### ❌ **Falta de Validação de Proposta Única**
O modelo `OrderService` aceita múltiplas propostas sem restrição:

```ruby
# app/models/order_service.rb
has_many :order_service_proposals, validate: false, dependent: :destroy
```

**NÃO HÁ VALIDAÇÃO** que impeça:
- Múltiplas propostas em status APROVADA
- Múltiplas propostas em status AUTORIZADA
- Criação de nova proposta quando já existe uma autorizada

#### ❌ **Cancelamento Sem Estorno de Saldo**
O método `cancel_order_service_proposal`:
- ✅ Muda o status para CANCELADA
- ❌ NÃO verifica se já foi autorizada
- ❌ NÃO estorna saldo consumido
- ❌ NÃO bloqueia cancelamento de proposta autorizada

#### ❌ **Autorização Sem Verificar Propostas Existentes**
O método `autorize_order_service_proposal`:
- ✅ Autoriza a proposta atual
- ❌ NÃO verifica se já existe proposta autorizada
- ❌ NÃO cancela automaticamente outras propostas
- ❌ Permite múltiplas autorizações na mesma OS

---

## 💰 RISCO DE CONSUMO DUPLO DE SALDO

### Verificação Necessária

Para confirmar se houve consumo duplo, é necessário verificar:

1. **Tabela `commitments` ou `balance_transactions`**
   ```sql
   -- Se houver controle de compromissos
   SELECT * FROM commitment_consumptions 
   WHERE order_service_proposal_id IN (P787_ID, P834_ID);
   
   -- Se houver controle de saldo direto
   SELECT * FROM balance_transactions 
   WHERE reference_id IN (P787_ID, P834_ID) 
   OR description LIKE '%P787%' OR description LIKE '%P834%';
   ```

2. **Auditorias das Propostas**
   ```sql
   SELECT * FROM audits 
   WHERE auditable_type = 'OrderServiceProposal'
   AND auditable_id IN (P787_ID, P834_ID)
   ORDER BY created_at;
   ```

3. **Status Atual da OS**
   ```sql
   SELECT id, code, order_service_status_id, client_id 
   FROM order_services 
   WHERE code = 'OS6657512026128';
   ```

### Cenários Possíveis

#### ✅ **CENÁRIO IDEAL** (baixo risco)
- P787 foi autorizada MAS nunca consumiu saldo
- Ao criar P834, o sistema só consumiu uma vez
- **Ação:** Apenas mudar P787 para CANCELADA

#### ⚠️ **CENÁRIO MÉDIO** (risco moderado)
- P787 foi autorizada E consumiu saldo
- P787 foi "cancelada" DEPOIS (mas saldo não foi estornado)
- P834 foi aprovada MAS ainda não consumiu saldo (está em NOTAS_INSERIDAS)
- **Ação:** Estornar saldo de P787 manualmente

#### 🚨 **CENÁRIO CRÍTICO** (risco alto)
- P787 foi autorizada E consumiu saldo
- P834 foi aprovada/autorizada E consumiu saldo NOVAMENTE
- **Consumo Duplo Confirmado!**
- **Ação:** Estornar saldo de P787, manter apenas P834

---

## 🔧 CORREÇÕES NECESSÁRIAS

### 1. Validação de Proposta Única por OS

**Arquivo:** `production/app/models/order_service_proposal.rb`

```ruby
# Adicionar validação customizada
validate :only_one_active_proposal_per_os, unless: :is_complement

private

def only_one_active_proposal_per_os
  return if order_service_id.nil?
  return if order_service_proposal_status_id.in?([
    OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
    OrderServiceProposalStatus::CANCELADA_ID,
    OrderServiceProposalStatus::EM_CADASTRO_ID
  ])
  
  # Buscar propostas ativas da mesma OS (exceto a atual)
  active_proposals = OrderService.find(order_service_id)
    .order_service_proposals
    .where.not(id: self.id)
    .where(order_service_proposal_status_id: 
      OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
  
  if active_proposals.exists?
    errors.add(:base, 
      "Já existe uma proposta ativa para esta OS. " \
      "Cancele a proposta anterior antes de criar/aprovar uma nova.")
  end
end
```

### 2. Bloquear Cancelamento de Proposta Autorizada

**Arquivo:** `production/app/controllers/order_service_proposals_controller.rb`

```ruby
def cancel_order_service_proposal
  authorize @order_service_proposal
  
  # ⚠️ VALIDAÇÃO: Não permitir cancelar proposta autorizada/paga
  if @order_service_proposal.order_service_proposal_status_id.in?([
    OrderServiceProposalStatus::AUTORIZADA_ID,
    OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
    OrderServiceProposalStatus::PAGA_ID
  ])
    flash[:error] = "Não é possível cancelar uma proposta que já foi autorizada. " \
                    "Entre em contato com o suporte."
    redirect_back(fallback_location: :back)
    return
  end
  
  @order_service_proposal.update_columns(
    order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID
  )
  OrderServiceProposal.generate_historic(...)
  flash[:success] = "Proposta cancelada com sucesso"
  redirect_back(fallback_location: :back)
end
```

### 3. Cancelar Outras Propostas ao Aprovar

**Arquivo:** `production/app/controllers/order_service_proposals_controller.rb`

```ruby
def approve_order_service_proposal
  authorize @order_service_proposal
  
  ActiveRecord::Base.transaction do
    # Cancelar outras propostas ativas da mesma OS (exceto complementos)
    @order_service_proposal.order_service.order_service_proposals
      .where.not(id: @order_service_proposal.id)
      .where(is_complement: [false, nil])
      .where(order_service_proposal_status_id: [
        OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID,
        OrderServiceProposalStatus::EM_ABERTO_ID
      ])
      .each do |other_proposal|
        other_proposal.update_columns(
          order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID
        )
        OrderServiceProposal.generate_historic(other_proposal, @current_user, 
          other_proposal.order_service_proposal_status_id, 
          OrderServiceProposalStatus::CANCELADA_ID)
      end
    
    # Aprovar a proposta atual
    # ... resto do código de aprovação
  end
end
```

### 4. Validar Antes de Autorizar

**Arquivo:** `production/app/controllers/order_service_proposals_controller.rb`

```ruby
def autorize_order_service_proposal
  authorize @order_service_proposal
  
  # Verificar se já existe proposta autorizada
  existing_authorized = @order_service_proposal.order_service.order_service_proposals
    .where.not(id: @order_service_proposal.id)
    .where(order_service_proposal_status_id: [
      OrderServiceProposalStatus::AUTORIZADA_ID,
      OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
      OrderServiceProposalStatus::PAGA_ID
    ])
  
  if existing_authorized.exists?
    flash[:error] = "Já existe uma proposta autorizada para esta OS " \
                    "(#{existing_authorized.first.code}). " \
                    "Não é possível autorizar múltiplas propostas."
    redirect_back(fallback_location: :back)
    return
  end
  
  # ... resto do código de autorização
end
```

---

## 📋 AÇÕES IMEDIATAS RECOMENDADAS

### 1. **URGENTE: Verificar Consumo de Saldo**
Executar script SQL para verificar se houve consumo duplo:

```ruby
# Script: check_double_balance_consumption.rb
os = OrderService.find_by(code: 'OS6657512026128')
p787 = os.order_service_proposals.find_by(code: 'P787OS6657512026128')
p834 = os.order_service_proposals.find_by(code: 'P834OS6657512026128')

puts "=== VERIFICAÇÃO DE CONSUMO ==="
puts "P787 Status: #{p787.order_service_proposal_status&.name}"
puts "P834 Status: #{p834.order_service_proposal_status&.name}"

if defined?(CommitmentConsumption)
  p787_consumptions = CommitmentConsumption.where(order_service_proposal_id: p787.id)
  p834_consumptions = CommitmentConsumption.where(order_service_proposal_id: p834.id)
  
  puts "\nP787 Consumos: #{p787_consumptions.sum(:value)}"
  puts "P834 Consumos: #{p834_consumptions.sum(:value)}"
  
  if p787_consumptions.any? && p834_consumptions.any?
    puts "\n⚠️ CONSUMO DUPLO DETECTADO!"
  end
end
```

### 2. **CORREÇÃO: Atualizar Status de P787**
Se P787 deve ser desconsiderada:

```ruby
# Mudar P787 para CANCELADA
p787.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID)
OrderServiceProposal.generate_historic(p787, current_user, 16, 20)
```

### 3. **ESTORNO: Reverter Consumo de P787** (se necessário)
Se P787 consumiu saldo indevidamente:

```ruby
# Estornar consumo de compromisso
CommitmentConsumption.where(order_service_proposal_id: p787.id).each do |consumption|
  consumption.update(deleted_at: Time.now) # Soft delete
  # OU
  commitment.consumed_value -= consumption.value
  commitment.save!
end

# Estornar saldo do cliente
client = os.client
client.balance += p787.total_value
client.save!
```

### 4. **IMPLEMENTAR: Validações de Segurança**
Aplicar as correções 1, 2, 3 e 4 listadas acima.

### 5. **AUDITORIA: Buscar Casos Similares**
Verificar se existem outras OSs com múltiplas propostas autorizadas:

```sql
SELECT 
  os.id AS os_id,
  os.code AS os_code,
  COUNT(osp.id) AS propostas_ativas
FROM order_services os
JOIN order_service_proposals osp ON osp.order_service_id = os.id
WHERE osp.order_service_proposal_status_id IN (14, 15, 16, 17, 18)
  AND (osp.is_complement IS NULL OR osp.is_complement = false)
GROUP BY os.id, os.code
HAVING COUNT(osp.id) > 1;
```

---

## 📊 RESUMO EXECUTIVO

### Problema
- **OS6657512026128 possui duas propostas em status ativos** (AUTORIZADA e NOTAS_INSERIDAS)
- **Risco de consumo duplo de saldo do cliente**
- **Falha permitiu aprovação/autorização de múltiplas propostas na mesma OS**

### Causa Raiz
1. ❌ Sistema não valida unicidade de proposta ativa por OS
2. ❌ Cancelamento não verifica se proposta já foi autorizada
3. ❌ Autorização não verifica propostas existentes
4. ❌ Aprovação não cancela automaticamente propostas concorrentes

### Impacto
- 🔴 **FINANCEIRO:** Possível consumo duplo de saldo/compromisso
- 🔴 **OPERACIONAL:** Dados inconsistentes (duas propostas "válidas")
- 🔴 **INTEGRIDADE:** Falta de controle sobre fluxo de aprovação

### Solução
1. ✅ Verificar IMEDIATAMENTE se houve consumo duplo
2. ✅ Corrigir status de P787 para CANCELADA
3. ✅ Estornar saldo se necessário
4. ✅ Implementar validações de proposta única
5. ✅ Bloquear cancelamento de propostas autorizadas
6. ✅ Cancelar automaticamente propostas concorrentes ao aprovar

### Proposta Correta a Manter
**P834OS6657512026128** - Esta é a proposta com os dados corretos (lavagem como serviço)

---

**Responsável pela Análise:** GitHub Copilot  
**Data:** 02/02/2026
