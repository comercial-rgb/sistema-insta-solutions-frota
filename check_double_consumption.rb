#!/usr/bin/env ruby
# Script para verificar consumo duplo de saldo na OS6657512026128

require_relative 'production/config/environment'

puts "=" * 80
puts "VERIFICAÇÃO DE CONSUMO DUPLO DE SALDO"
puts "OS6657512026128"
puts "=" * 80

# Buscar OS e propostas
os = OrderService.unscoped.find_by(code: 'OS6657512026128')

unless os
  puts "❌ OS não encontrada!"
  exit
end

puts "\n📋 OS: #{os.code} (ID: #{os.id})"
puts "Cliente: #{os.client&.fantasy_name} (ID: #{os.client_id})"
puts "Status OS: #{os.order_service_status&.name}"

# Buscar as duas propostas
p787 = os.order_service_proposals.unscoped.find_by("code LIKE ?", "%P787%")
p834 = os.order_service_proposals.unscoped.find_by("code LIKE ?", "%P834%")

unless p787 && p834
  puts "\n⚠️  Não foram encontradas ambas as propostas!"
  puts "P787 encontrada: #{p787.present?}"
  puts "P834 encontrada: #{p834.present?}"
  exit
end

puts "\n" + "=" * 80
puts "📝 PROPOSTAS"
puts "=" * 80

[p787, p834].each do |proposta|
  puts "\nProposta: #{proposta.code} (ID: #{proposta.id})"
  puts "Status: #{proposta.order_service_proposal_status&.name} (ID: #{proposta.order_service_proposal_status_id})"
  puts "Valor Total: R$ #{proposta.total_value&.to_f}"
  puts "Data Criação: #{proposta.created_at}"
  puts "Autorizada em: #{proposta.authorized_at || 'Não autorizada'}"
end

# Verificar se há tabela de consumo de compromissos
puts "\n" + "=" * 80
puts "💰 VERIFICAÇÃO DE CONSUMO"
puts "=" * 80

total_consumido_p787 = 0
total_consumido_p834 = 0
consumo_duplicado = false

# Verificar CommitmentConsumption
if defined?(CommitmentConsumption)
  puts "\n✅ Sistema usa CommitmentConsumption"
  
  p787_consumptions = CommitmentConsumption.where(order_service_proposal_id: p787.id)
  p834_consumptions = CommitmentConsumption.where(order_service_proposal_id: p834.id)
  
  puts "\nP787 - Consumos encontrados: #{p787_consumptions.count}"
  p787_consumptions.each do |c|
    ativo = c.deleted_at.nil?
    puts "  - R$ #{c.value} (#{ativo ? 'ATIVO' : 'CANCELADO'}) - #{c.created_at}"
    total_consumido_p787 += c.value.to_f if ativo
  end
  
  puts "\nP834 - Consumos encontrados: #{p834_consumptions.count}"
  p834_consumptions.each do |c|
    ativo = c.deleted_at.nil?
    puts "  - R$ #{c.value} (#{ativo ? 'ATIVO' : 'CANCELADO'}) - #{c.created_at}"
    total_consumido_p834 += c.value.to_f if ativo
  end
  
  if p787_consumptions.where(deleted_at: nil).any? && p834_consumptions.where(deleted_at: nil).any?
    consumo_duplicado = true
  end
else
  puts "\n⚠️  Sistema NÃO usa CommitmentConsumption"
end

# Verificar BalanceTransaction
if defined?(BalanceTransaction)
  puts "\n✅ Sistema usa BalanceTransaction"
  
  p787_transactions = BalanceTransaction.where("description LIKE ? OR reference_id = ?", "%#{p787.code}%", p787.id)
  p834_transactions = BalanceTransaction.where("description LIKE ? OR reference_id = ?", "%#{p834.code}%", p834.id)
  
  puts "\nP787 - Transações encontradas: #{p787_transactions.count}"
  p787_transactions.each do |t|
    puts "  - R$ #{t.amount} - #{t.description} - #{t.created_at}"
  end
  
  puts "\nP834 - Transações encontradas: #{p834_transactions.count}"
  p834_transactions.each do |t|
    puts "  - R$ #{t.amount} - #{t.description} - #{t.created_at}"
  end
  
  if p787_transactions.any? && p834_transactions.any?
    consumo_duplicado = true
  end
else
  puts "\n⚠️  Sistema NÃO usa BalanceTransaction"
end

# Verificar saldo do cliente
puts "\n" + "=" * 80
puts "👤 CLIENTE"
puts "=" * 80

client = os.client
if client
  puts "\nCliente: #{client.fantasy_name}"
  puts "Saldo Atual: R$ #{client.balance&.to_f || 'N/A'}"
  
  if os.commitment
    puts "\n📄 Compromisso: #{os.commitment.description || os.commitment.id}"
    puts "Valor do Compromisso: R$ #{os.commitment.value&.to_f}"
    puts "Valor Consumido: R$ #{os.commitment.consumed_value&.to_f}"
    puts "Saldo Restante: R$ #{(os.commitment.value.to_f - os.commitment.consumed_value.to_f)}"
  else
    puts "\n⚠️  OS sem compromisso vinculado"
  end
end

# Histórico de mudanças
puts "\n" + "=" * 80
puts "📜 HISTÓRICO DE STATUS"
puts "=" * 80

[p787, p834].each do |proposta|
  puts "\n#{proposta.code}:"
  audits = proposta.audits.where("audited_changes LIKE ?", "%order_service_proposal_status_id%").order(:created_at)
  
  if audits.any?
    audits.each do |audit|
      if audit.audited_changes['order_service_proposal_status_id']
        old_id, new_id = audit.audited_changes['order_service_proposal_status_id']
        old_status = OrderServiceProposalStatus.find_by(id: old_id)&.name || 'N/A'
        new_status = OrderServiceProposalStatus.find_by(id: new_id)&.name || 'N/A'
        puts "  #{audit.created_at} - #{old_status} → #{new_status}"
      end
    end
  else
    puts "  Sem histórico de mudanças de status"
  end
end

# Diagnóstico final
puts "\n" + "=" * 80
puts "🔍 DIAGNÓSTICO"
puts "=" * 80

puts "\n1. Status Atual:"
puts "   P787: #{p787.order_service_proposal_status&.name}"
puts "   P834: #{p834.order_service_proposal_status&.name}"

puts "\n2. Consumo de Saldo:"
puts "   P787: R$ #{total_consumido_p787}"
puts "   P834: R$ #{total_consumido_p834}"
puts "   Total: R$ #{total_consumido_p787 + total_consumido_p834}"

if consumo_duplicado
  puts "\n🚨 CONSUMO DUPLICADO DETECTADO!"
  puts "   Ambas as propostas consumiram recursos do cliente."
  puts "   É necessário estornar o consumo de P787."
elsif total_consumido_p787 > 0 && total_consumido_p834 == 0
  puts "\n⚠️  CONSUMO APENAS EM P787"
  puts "   P787 consumiu recursos mas P834 (proposta correta) não."
  puts "   Verificar se P834 deve consumir ou se P787 deve ser estornada."
elsif total_consumido_p787 == 0 && total_consumido_p834 > 0
  puts "\n✅ CONSUMO APENAS EM P834"
  puts "   Apenas P834 (proposta correta) consumiu recursos."
  puts "   Situação mais segura, mas P787 deve ser cancelada."
else
  puts "\n⚠️  NENHUM CONSUMO DETECTADO"
  puts "   Verificar se o sistema não usa as tabelas consultadas."
end

puts "\n3. Status Esperado:"
puts "   P787: CANCELADA (ID 20)"
puts "   P834: Manter status atual (NOTAS_INSERIDAS)"

puts "\n4. Ações Recomendadas:"
if p787.order_service_proposal_status_id != OrderServiceProposalStatus::CANCELADA_ID
  puts "   ❌ P787 está como #{p787.order_service_proposal_status&.name}"
  puts "   → Executar: ruby fix_os_6657512026128.rb"
end

if consumo_duplicado
  puts "   ❌ Consumo duplicado detectado"
  puts "   → Executar script de estorno manual"
end

puts "\n" + "=" * 80
puts "FIM DA VERIFICAÇÃO"
puts "=" * 80
