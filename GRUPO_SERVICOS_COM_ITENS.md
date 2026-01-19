# Funcionalidade: Grupo de Serviços com Peças e Serviços

## Objetivo
Permitir que Grupos de Serviços tenham peças e serviços cadastrados, e que Ordens de Serviço do tipo Requisição só possam usar itens dentro do grupo selecionado, respeitando limites de quantidade e valor.

## Implementação

### 1. Nova Tabela: `service_group_items`
**Arquivo**: `db/migrate/20260110120000_create_service_group_items.rb`

Campos:
- `service_group_id` - Referência ao grupo
- `service_id` - Referência à peça/serviço
- `quantity` - Quantidade limite permitida
- `max_value` - Valor máximo permitido (R$)
- Índice único para evitar duplicatas: `[service_group_id, service_id]`

### 2. Novo Modelo: `ServiceGroupItem`
**Arquivo**: `app/models/service_group_item.rb`

**Validações**:
- `service_id` obrigatório e único por grupo
- `quantity` obrigatória e maior que 0
- `max_value` obrigatório e maior ou igual a 0

**Métodos úteis**:
- `service_name` - Nome da peça/serviço
- `formatted_max_value` - Valor formatado (R$ 1.234,56)
- `formatted_quantity` - Quantidade formatada (123,45)

### 3. Modelo `ServiceGroup` Atualizado
**Arquivo**: `app/models/service_group.rb`

**Novas associações**:
```ruby
has_many :service_group_items, dependent: :destroy
has_many :services, through: :service_group_items
accepts_nested_attributes_for :service_group_items, allow_destroy: true, reject_if: :all_blank
```

### 4. Formulário de Grupo de Serviços
**Arquivo**: `app/views/service_groups/_form.html.erb`

**Nova seção**: "Peças e Serviços do Grupo"
- Adicionar múltiplos itens
- Selecionar peça/serviço
- Definir quantidade limite
- Definir valor máximo
- Remover itens

**Funcionalidade JavaScript**:
- Botão "Adicionar Peça/Serviço" adiciona novo campo dinamicamente
- Botão "Remover" exclui item (soft delete para items persistidos)
- Máscaras de dinheiro aplicadas automaticamente

### 5. Controller Atualizado
**Arquivo**: `app/controllers/service_groups_controller.rb`

**Parâmetros permitidos**:
```ruby
service_group_items_attributes: [:id, :service_id, :quantity, :max_value, :_destroy]
```

### 6. Validações em OrderService
**Arquivo**: `app/models/order_service.rb`

**Nova validação**: `validate_services_in_service_group`

**Regras para OS tipo Requisição**:
1. ✅ Grupo deve ter itens cadastrados
2. ✅ Peças/serviços selecionados devem estar no grupo
3. ✅ Quantidade não pode exceder limite do grupo
4. ✅ Valor total do item não pode exceder limite do grupo

**Mensagens de erro**:
- "O grupo de serviço [Nome] não possui peças/serviços cadastrados"
- "A peça/serviço '[Nome]' não está cadastrada no grupo [Grupo]"
- "Quantidade de '[Nome]' (X) excede o limite do grupo (Y)"
- "Valor total de '[Nome]' (R$ X) excede o limite do grupo (R$ Y)"

### 7. Traduções
**Arquivo**: `config/locales/service_group_item.yml`

Labels em português para todos os campos do modelo.

## Como Usar

### Cadastrar Grupo de Serviços:
1. Acesse **Grupo de Serviços**
2. Crie/edite um grupo
3. Preencha o nome (aparecerá na OS)
4. Clique em "+ Adicionar Peça/Serviço"
5. Selecione a peça ou serviço
6. Defina **Quantidade Limite**
7. Defina **Valor Máximo** (R$)
8. Repita para todas as peças/serviços do grupo
9. Salve

### Criar OS do Tipo Requisição:
1. Selecione o **Grupo de Serviço**
2. Só poderá adicionar peças/serviços cadastrados no grupo
3. Sistema validará:
   - Quantidade não excede limite
   - Valor unitário × quantidade não excede limite
   - Valor total da OS não excede `value_limit` do grupo

## Migração
```bash
rails db:migrate
```

## Arquivos Criados/Modificados

### Criados:
- `db/migrate/20260110120000_create_service_group_items.rb`
- `app/models/service_group_item.rb`
- `app/views/service_groups/_service_group_item_fields.html.erb`
- `config/locales/service_group_item.yml`

### Modificados:
- `app/models/service_group.rb`
- `app/models/order_service.rb`
- `app/controllers/service_groups_controller.rb`
- `app/views/service_groups/_form.html.erb`
- `app/models/commitment.rb` (remoção de validação category_id)

## Benefícios

✅ **Controle preciso**: Define exatamente quais peças/serviços podem ser usados  
✅ **Limites individuais**: Cada item tem quantidade e valor máximo  
✅ **Validação automática**: Sistema impede valores acima do permitido  
✅ **Rastreabilidade**: Audited registra todas as mudanças  
✅ **Interface intuitiva**: Adicionar/remover itens dinamicamente

## Exemplo de Uso

**Grupo**: "Manutenção Preventiva Básica"
- Valor limite do grupo: R$ 500,00

**Itens cadastrados**:
1. **Óleo Motor** - Qtd: 4L, Valor máx: R$ 120,00
2. **Filtro de Óleo** - Qtd: 1, Valor máx: R$ 50,00
3. **Mão de Obra Troca** - Qtd: 1, Valor máx: R$ 150,00

**Ao criar OS Requisição**:
- Só pode selecionar esses 3 itens
- Não pode colocar 5L de óleo (limite: 4L)
- Não pode cobrar R$ 130,00 pelo óleo (limite: R$ 120,00)
- Valor total não pode passar de R$ 500,00
