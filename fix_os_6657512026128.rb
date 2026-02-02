#!/usr/bin/env ruby
# Script para corrigir status de P787 e evitar consumo duplo

require_relative 'production/config/environment'

puts "=" * 80
puts "CORREÇÃO: OS6657512026128 - Cancelar P787"
puts "=" * 80

# Buscar OS e propostas
os = OrderService.unscoped.find_by(code: 'OS6657512026128')

unless os
  puts "❌ OS não encontrada!"
  exit
end

p787 = os.order_service_proposals.unscoped.find_by("code LIKE ?", "%P787%")
p834 = os.order_service_proposals.unscoped.find_by("code LIKE ?", "%P834%")

unless p787
  puts "❌ Proposta P787 não encontrada!"
  exit
end

puts "\n📋 Proposta P787 (ID: #{p787.id})"
puts "Status Atual: #{p787.order_service_proposal_status&.name} (ID: #{p787.order_service_proposal_status_id})"
puts "Valor: R$ #{p787.total_value}"

# Confirmar ação
puts "\n⚠️  ESTA AÇÃO VAI:"
puts "1. Alterar o status de P787 para CANCELADA"
puts "2. Gerar histórico de auditoria"
puts "3. NÃO irá estornar saldo automaticamente (fazer manualmente se necessário)"

print "\n Continuar? (digite 'SIM' para confirmar): "
confirmacao = STDIN.gets.chomp

unless confirmacao.upcase == 'SIM'
  puts "\n❌ Operação cancelada pelo usuário."
  exit
end

# Executar correção
begin
  ActiveRecord::Base.transaction do
    old_status_id = p787.order_service_proposal_status_id
    
    # Atualizar status para CANCELADA
    p787.update_columns(
      order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID,
      updated_at: Time.now
    )
    
    # Gerar histórico de auditoria
    audit = p787.audits.create!(
      user_id: 1, # ID do admin (ajustar conforme necessário)
      action: 'update',
      audited_changes: {
        'order_service_proposal_status_id' => [old_status_id, OrderServiceProposalStatus::CANCELADA_ID],
        'order_service_proposal_status' => [
          OrderServiceProposalStatus.find_by(id: old_status_id)&.name,
          'Cancelada'
        ]
      },
      comment: 'Cancelamento automático via script - Proposta P787 foi substituída por P834',
      created_at: Time.now
    )
    
    puts "\n✅ Status atualizado com sucesso!"
    puts "   De: #{OrderServiceProposalStatus.find_by(id: old_status_id)&.name}"
    puts "   Para: CANCELADA"
    puts "   Audit ID: #{audit.id}"
    
    # Verificar se há consumo de saldo a estornar
    if defined?(CommitmentConsumption)
      consumptions = CommitmentConsumption.where(
        order_service_proposal_id: p787.id,
        deleted_at: nil
      )
      
      if consumptions.any?
        puts "\n⚠️  ATENÇÃO: P787 possui consumos ativos:"
        consumptions.each do |c|
          puts "   - R$ #{c.value} no compromisso ID #{c.commitment_id}"
        end
        puts "\n   Execute o script de estorno manualmente se necessário:"
        puts "   ruby estornar_saldo_p787.rb"
      else
        puts "\n✅ Nenhum consumo ativo encontrado para P787"
      end
    end
    
    puts "\n✅ CORREÇÃO CONCLUÍDA!"
  end
rescue => e
  puts "\n❌ ERRO ao executar correção:"
  puts "   #{e.message}"
  puts "   #{e.backtrace.first(5).join("\n   ")}"
end

# Verificar resultado
puts "\n" + "=" * 80
puts "VERIFICAÇÃO PÓS-CORREÇÃO"
puts "=" * 80

p787.reload
p834.reload

puts "\nP787:"
puts "  Status: #{p787.order_service_proposal_status&.name}"
puts "  Última atualização: #{p787.updated_at}"

puts "\nP834:"
puts "  Status: #{p834.order_service_proposal_status&.name}"
puts "  Última atualização: #{p834.updated_at}"

puts "\nOS #{os.code}:"
puts "  Status: #{os.order_service_status&.name}"
puts "  Propostas ativas: #{os.order_service_proposals.where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES).count}"

puts "\n" + "=" * 80
