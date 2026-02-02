# Correções Pendentes - 26/01/2026

## ✅ CORRIGIDAS NESTA SESSÃO:

1. **Status duplicado** - menu_helper.rb corrigido
2. **IDs tipos de OS** - JavaScript corrigido (3=Requisição, 4=Cotações, 5=Diagnóstico)
3. **Encoding** - Script consolidado executado (1.966 registros)

---

## 📋 CORREÇÕES SQL RESTANTES:

### 1. Encoding com caracteres duplicados

Execute no MySQL:

```sql
-- Corrigir "çãoo" → "ção", "Pe??as" → "Peças", etc
UPDATE users SET name = REPLACE(REPLACE(REPLACE(name, 'çãoo', 'ção'), 'Pe??as', 'Peças'), 'Ibiraçãou', 'Ibirá') WHERE name LIKE '%çãoo%' OR name LIKE '%??%' OR name LIKE '%çãou%';

UPDATE services SET 
  name = REPLACE(REPLACE(REPLACE(REPLACE(name, 'çãoo', 'ção'), 'Administraçãoo', 'Administração'), 'Integraçãoo', 'Integração'), 'Pe??as', 'Peças')
WHERE name LIKE '%çãoo%' OR name LIKE '%Administraçãoo%' OR name LIKE '%Integraçãoo%' OR name LIKE '%??%';

UPDATE provider_service_types SET 
  name = REPLACE(REPLACE(name, 'çãoo', 'ção'), 'Pe??as', 'Peças')
WHERE name LIKE '%çãoo%' OR name LIKE '%??%';

UPDATE contracts SET 
  name = REPLACE(name, 'çãoo', 'ção')
WHERE name LIKE '%çãoo%';

UPDATE cost_centers SET 
  name = REPLACE(name, 'çãoo', 'ção')
WHERE name LIKE '%çãoo%';

UPDATE vehicles SET 
  current_owner_name = REPLACE(current_owner_name, 'çãoo', 'ção')
WHERE current_owner_name LIKE '%çãoo%';

UPDATE notifications SET 
  title = REPLACE(title, 'çãoo', 'ção'),
  message = REPLACE(message, 'çãoo', 'ção')
WHERE title LIKE '%çãoo%' OR message LIKE '%çãoo%';

UPDATE orientation_manuals SET 
  name = REPLACE(name, 'çãoo', 'ção'),
  description = REPLACE(description, 'çãoo', 'ção')
WHERE name LIKE '%çãoo%' OR description LIKE '%çãoo%';
```

---

## 🔍 VERIFICAÇÕES MANUAIS NECESSÁRIAS:

### 2. Dashboard - Filtro de cliente para Admin

**Arquivo:** `app/controllers/order_services_controller.rb` método `dashboard` (linha 28)

**Problema:** Admin deve ver dados de TODOS os clientes por padrão, e só filtrar quando seleciona um cliente específico

**Verificar:** A lógica já está implementada (linhas 42-75), mas precisa testar:
- Admin sem filtro = todos os dados
- Admin com filtro cliente = só aquele cliente
- Gestor/Adicional = sempre só seu cliente

**Status:** Aparentemente correto, mas TESTAR após reiniciar servidor

---

### 3. Vehicles - Valor gasto em manutenção zerado

**Arquivo:** Provavelmente em `app/models/vehicle.rb` ou view de vehicles

**Ação:** 
1. Procurar método que calcula "valor gasto em manutenção"
2. Verificar se está usando os status corretos (REQUIRED_ORDER_SERVICE_STATUSES)
3. Possível causa: usava IDs antigos ou não inclui todos os status necessários

**Comando para investigar:**
```bash
grep -r "gasto.*manutenção" app/models/vehicle.rb
grep -r "maintenance.*spent" app/models/vehicle.rb
```

---

### 4. Correção de paginação (contracts, cost_centers, commitments, vehicles)

**Problema relatado:** "a correção de página aplicada em contracts, cost_centers, commitments e vehicles conferir se está aplicada"

**Ação:** Não ficou claro qual correção específica. Verificar:
- Paginação funciona corretamente?
- Filtros funcionam?
- Export funciona?

**Testar manualmente** após reiniciar servidor

---

### 5. show_invoices - Filtro de status

**Arquivo:** Provavelmente `app/controllers/order_services_controller.rb` método `show_invoices`

**Problema:** "puxar somente o status Autorizada quando sai de Nota fiscal inserida, não puxar quando sai de Autorizada Aguardando pagamento"

**Lógica esperada:**
```
Status anterior = Nota fiscal inserida (ID 4)
  → Mostrar em show_invoices

Status anterior = Autorizada (ID 5) 
  → NÃO mostrar em show_invoices

Status anterior = Aguardando pagamento (ID 6)
  → NÃO mostrar em show_invoices
```

**Ação:** Verificar a query em show_invoices e ajustar o filtro

---

### 6. show_invoices - Layout quebrado

**Problema:** "em show_invoices a página apresenta erros em seu layout"

**Arquivos possíveis:**
- `app/views/order_services/show_invoices.html.erb`
- `app/assets/stylesheets/order_services.scss`

**Ação:** 
1. Acessar a rota show_invoices
2. Verificar erros no console do navegador (F12)
3. Corrigir CSS ou HTML conforme necessário

---

## ⚡ PRÓXIMOS PASSOS IMEDIATOS:

1. **Executar SQL de encoding** (acima)
2. **Reiniciar servidor Rails**
3. **Testar** cada funcionalidade reportada
4. **Verificar logs** para erros de ConnectionTimeout
5. **Ajustar** conforme necessário

---

## 🔧 COMANDOS ÚTEIS:

```powershell
# Executar SQL de encoding
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -prot123 sistema_insta_solutions_development < correções_encoding.sql

# Reiniciar servidor
.\restart-clear.ps1

# Verificar logs em tempo real
Get-Content log\development.log -Tail 50 -Wait

# Criar backup após correções
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe" -u root -prot123 sistema_insta_solutions_development > "banco_pos_correcoes_$timestamp.sql"
```

---

## 🐛 ERRO ConnectionTimeout:

**Sintoma:** `ActiveRecord::ConnectionTimeoutError - could not obtain a connection from the pool within 5.000 seconds`

**Causa:** Pool de conexões esgotado (conexões não sendo liberadas)

**Soluções:**

1. **Aumentar pool** em `config/database.yml`:
```yaml
development:
  pool: 20  # Era 5, aumentar para 20
```

2. **Verificar conexões abertas:**
```sql
SHOW PROCESSLIST;
```

3. **Reiniciar MySQL se necessário:**
```powershell
Restart-Service MySQL80
```

---

**Última atualização:** 26/01/2026 23:59
