# Correções Finais - 26/01/2026

## ✅ Correções Já Aplicadas

### 1. Encoding no Banco de Dados
- ✅ Primeira rodada: `çãoo`, `Pe??as`, `Integraçãoo`, `Administraçãoo`, `Ibiraçãou`
- ✅ Segunda rodada: `óo`, `óa`, `bujóo`, `CARCAóA`
- Executado em: services, provider_service_types, contracts, cost_centers, vehicles, notifications, orientation_manuals

### 2. Pool de Conexões
- ✅ config/database.yml: pool aumentado de 5 para 20
- Deve resolver ConnectionTimeoutError

### 3. Constantes de Status (Sessão Anterior)
- ✅ app/models/order_service_status.rb: IDs corrigidos (1-11)
- ✅ app/helpers/menu_helper.rb: Status duplicado removido
- ✅ app/assets/javascripts/models/order_services.js: IDs de tipos corrigidos

## ⚠️ Problemas Restantes

### 1. Acesso Não Permitido - Status "Em Aberto"

**Problema**: Ao clicar em "Em aberto", usuário admin recebe "Acesso não permitido"

**Causa Provável**: 
- O grid OrderServicesGrid pode não estar sendo inicializado corretamente
- O scope by_order_service_status_id pode estar sendo aplicado incorretamente
- Permissão show_order_services? está OK (permite qualquer usuário logado)

**Solução**: Verificar no log/development.log o erro específico quando ocorre

**SQL para Debug**:
```sql
-- Verificar se há OSs com status 1 (Em Aberto)
SELECT id, code, client_id, order_service_status_id 
FROM order_services 
WHERE order_service_status_id = 1 
LIMIT 10;
```

**Próximos Passos**:
1. Reiniciar servidor
2. Fazer login como admin
3. Clicar em "Em aberto"
4. Verificar log: `tail -f log/development.log`
5. Identificar erro específico de policy ou query

---

### 2. Dashboard - Filtro de Cliente para Admin

**Requisito**: 
- Admin SEM filtro → ver TODOS os clientes
- Admin COM filtro de cliente → ver só aquele cliente
- Gestores/Adicionais → ver só seu cliente

**Código Atual**: Parece correto (linhas 28-73 de order_services_controller.rb)

**Teste Necessário**:
1. Login como admin
2. Acessar dashboard
3. Verificar se mostra dados de todos os clientes
4. Aplicar filtro de cliente específico
5. Verificar se filtra corretamente

---

### 3. Vehicles - "Valor gasto em manutenção" Zerado

**Método**: `app/models/vehicle.rb#get_total_paid_value` (linha 133)

**Lógica Atual**:
```ruby
def get_total_paid_value
  result = 0
  invoiced_order_services = self.order_services.select{|item| 
    [OrderServiceStatus::AUTORIZADA_ID, 
     OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID, 
     OrderServiceStatus::PAGA_ID].include?(item.order_service_status_id)
  }
  invoiced_order_services.each do |order_service|
    order_service_proposal = order_service.order_service_proposals.select{|item| 
      [OrderServiceProposalStatus::AUTORIZADA_ID, 
       OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID, 
       OrderServiceProposalStatus::PAGA_ID].include?(item.order_service_proposal_status_id)
    }.last
    if order_service_proposal
      result += order_service_proposal.total_value
    end
  end
  return result
end
```

**Problema Potencial**:
- IDs das constants estão corretos: AUTORIZADA_ID=5, AGUARDANDO_PAGAMENTO_ID=6, PAGA_ID=7
- MAS OrderServiceProposalStatus pode ter IDs DIFERENTES

**SQL para Verificar**:
```sql
-- Ver IDs dos status de proposta
SELECT id, name FROM order_service_proposal_statuses ORDER BY id;

-- Ver um veículo com OSs para calcular manualmente
SELECT v.id, v.board, os.id as os_id, os.order_service_status_id, 
       osp.id as prop_id, osp.order_service_proposal_status_id, osp.total_value
FROM vehicles v
JOIN order_services os ON os.vehicle_id = v.id
LEFT JOIN order_service_proposals osp ON osp.order_service_id = os.id
WHERE v.id = 1
  AND os.order_service_status_id IN (5, 6, 7)
ORDER BY os.id, osp.id;
```

**Possível Solução**:
Verificar se os IDs de OrderServiceProposalStatus são:
- AUTORIZADA_ID = ?
- AGUARDANDO_PAGAMENTO_ID = ?
- PAGA_ID = ?

---

### 4. Correção de Paginação

**Verificar se aplicada em**:
- contracts (app/views/contracts/index.html.erb)
- cost_centers (app/views/cost_centers/index.html.erb)
- commitments (app/views/commitments/index.html.erb)
- vehicles (app/views/vehicles/index.html.erb)

**Buscar por**: `<%= paginate @items %>` ou `will_paginate`

---

### 5. show_invoices - Filtro de Status

**Requisito**: 
"puxar somente o status Autorizada quando sai de Nota fiscal inserida, não puxar quando sai de Autorizada ou Aguardando pagamento"

**Entendimento**:
- Mostrar OS quando: anterior = "Nota fiscal inserida" (4) → atual = "Autorizada" (5)
- NÃO mostrar quando: anterior = "Autorizada" (5) → atual = "Aguardando pagamento" (6)
- NÃO mostrar quando: anterior = "Aguardando pagamento" (6) → atual = "Paga" (7)

**Lógica Atual** (linha 22-24):
```ruby
def show_invoices
  authorize OrderService
  defining_data(nil, true, nil, true, true, params[:order_services_invoice_grid], 
                OrderServicesInvoiceGrid, 'show_invoices')
end
```

Usa `filter_audit = true` para buscar por histórico.

**Correção Necessária**:
Adicionar filtro para verificar o status ANTERIOR na tabela `audits`:

```ruby
# Dentro do defining_data quando method == "show_invoices"
# Filtrar OSs que passaram de Nota Fiscal Inserida (4) para Autorizada (5)
scope.joins(:audits)
  .where('audits.audited_changes LIKE ?', '%order_service_status_id%')
  .where('audits.audited_changes LIKE ?', '%- 4%') # De: Nota Fiscal Inserida
  .where('audits.audited_changes LIKE ?', '%- 5%') # Para: Autorizada
  .where(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)
```

---

### 6. show_invoices - Layout Quebrado

**Problema**: "a página apresenta erros em seu layout"

**Investigação Necessária**:
1. Acessar /show_invoices
2. Abrir DevTools (F12)
3. Verificar:
   - Console: erros JavaScript
   - Network: recursos 404
   - Elements: problemas de CSS

**Possíveis Causas**:
- CSS faltando classe
- JavaScript com erro (bloqueia rendering)
- Grid com colunas mal formatadas
- Imagens/assets faltando

---

## 🔧 Comandos Úteis

### Verificar Encoding
```sql
SELECT name FROM services 
WHERE name LIKE '%ção%' OR name LIKE '%ças%' 
LIMIT 20;
```

### Verificar Status OSs
```sql
SELECT order_service_status_id, COUNT(*) as total 
FROM order_services 
GROUP BY order_service_status_id 
ORDER BY order_service_status_id;
```

### Verificar Valor Gasto Veículos
```sql
SELECT v.board, 
       COUNT(DISTINCT os.id) as total_os,
       SUM(CASE WHEN os.order_service_status_id IN (5,6,7) THEN 1 ELSE 0 END) as os_pagas,
       GROUP_CONCAT(DISTINCT osp.order_service_proposal_status_id) as prop_status_ids
FROM vehicles v
LEFT JOIN order_services os ON os.vehicle_id = v.id
LEFT JOIN order_service_proposals osp ON osp.order_service_id = os.id
WHERE v.id <= 10
GROUP BY v.id
ORDER BY v.id;
```

### Reiniciar Servidor
```powershell
.\restart-clear.ps1
```

### Ver Logs
```powershell
Get-Content .\log\development.log -Tail 50 -Wait
```

---

## 📋 Checklist de Testes

### Após Reiniciar Servidor:

- [ ] Login como Admin
- [ ] Clicar em "Em aberto" → deve listar 58 OSs sem erro
- [ ] Dashboard sem filtro → deve mostrar todos os clientes
- [ ] Dashboard com filtro Cliente → deve filtrar
- [ ] Verificar encoding em listas (sem `???`, `óo`, etc.)
- [ ] Vehicles → verificar se "Valor gasto" não está zerado
- [ ] show_invoices → verificar layout e filtro
- [ ] Nenhum ConnectionTimeoutError

### Login como Gestor:

- [ ] Dashboard → ver só seu cliente
- [ ] "Em aberto" → ver só suas OSs
- [ ] Filtros funcionando

---

## 📝 Próximos Passos (Ordem de Prioridade)

1. **REINICIAR SERVIDOR** (aplicar alterações do pool e encoding)
2. **Testar acesso "Em aberto"** como admin (investigar erro específico)
3. **Verificar IDs de OrderServiceProposalStatus** (para corrigir valor gasto veículos)
4. **Corrigir filtro show_invoices** (usar audits para verificar transição 4→5)
5. **Investigar layout show_invoices** (DevTools F12)
6. **Testar paginação** em contracts, cost_centers, commitments, vehicles
7. **Teste completo** como admin, gestor, adicional

