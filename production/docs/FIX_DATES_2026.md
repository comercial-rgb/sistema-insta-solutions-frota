# Guia de Correção: Datas 2026 → 2025

## Problema Identificado

Durante a importação/integração do banco de dados, registros foram criados com ano **2026** ao invés de **2025**. Isso afeta:

- **1.121 Audits** (histórico de mudanças de status)
- **139 OrderServices** (created_at)
- **143 OrderServices** (updated_at)
- **126 Proposals** (created_at)
- **134 Proposals** (updated_at)
- **69 Invoices** (created_at + emission_date)
- **85 Vehicles**
- **28 Users**

## Impacto

O principal impacto está na **aba de Faturas**, que mostra 104 OSs no filtro de "janeiro 2026" porque os audits de aprovação foram registrados como `2026-01-05` ao invés de `2025-01-05`.

## Solução

### Opção 1: Correção Automática (RECOMENDADO)

Execute o script de correção completa:

```powershell
rails runner scripts/fix_all_dates_2026_to_2025.rb
```

Este script irá:
1. Analisar todos os registros com data entre 2026-01-01 e 2026-01-23
2. Subtrair 1 ano de todas as datas afetadas
3. Corrigir em uma transação (rollback automático em caso de erro)
4. Mostrar estatísticas e resultados

**⚠️ IMPORTANTE: Faça backup do banco antes de executar!**

### Opção 2: Correção Manual (apenas Audits)

Se preferir corrigir apenas os audits (histórico de aprovações):

```powershell
rails runner scripts/fix_audit_dates_2026_to_2025.rb
```

Este script corrige apenas a tabela `audits`, que é a causa principal do problema na aba Faturas.

## Verificação

Após a correção, você pode verificar se ainda existem registros com data 2026:

```powershell
rails runner tmp/analyze_all_dates_2026.rb
```

## Resultado Esperado

Após a correção:
- ✅ Aba Faturas mostrará corretamente as OSs em **janeiro 2025**
- ✅ Histórico de aprovações (audits) terá datas corretas
- ✅ OrderServices, Proposals e Invoices terão timestamps corretos
- ✅ Relatórios e filtros por data funcionarão corretamente

## Comandos de Verificação Rápida

**Ver quantas OSs aparecem em janeiro 2025 (depois da correção):**
```ruby
rails runner 'puts OrderService.approved_in_period("2025-01-01", "2025-01-31").count'
```

**Ver quantas OSs ainda aparecem em janeiro 2026 (deve ser 0):**
```ruby
rails runner 'puts OrderService.approved_in_period("2026-01-01", "2026-01-31").count'
```

## Prevenção Futura

Para evitar este problema em futuras importações:
1. ✅ Verifique a data do sistema antes de importar dados
2. ✅ Valide as datas nos arquivos de importação
3. ✅ Use seeds/migrations com datas relativas (`Date.today` ao invés de datas fixas)
4. ✅ Execute `tmp/analyze_all_dates_2026.rb` após importações para detectar problemas

## Dúvidas?

- Os scripts usam **transações** - se houver erro, nenhuma alteração é aplicada
- Todos os scripts mostram **estatísticas antes** de executar
- É solicitada **confirmação** antes de fazer qualquer alteração
- Faça **backup do banco** antes de executar qualquer correção em massa
