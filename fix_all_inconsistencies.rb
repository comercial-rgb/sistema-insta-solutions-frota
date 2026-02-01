# Script para corrigir TODAS as OSs com status inconsistente
puts "=== CORREÇÃO EM MASSA DE INCONSISTÊNCIAS ==="
puts "Data/Hora: #{Time.now.strftime('%d/%m/%Y %H:%M:%S')}\n\n"

admin_user = User.find_by(profile_id: 1) || User.first
corrected_count = 0
errors = []

# Buscar OSs com propostas aprovadas mas status diferente de APROVADA
inconsistent_os = OrderService.joins(:order_service_proposals)
  .where(order_service_proposals: { order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID })
  .where.not(order_service_status_id: OrderServiceStatus::APROVADA_ID)
  .distinct

puts "OSs encontradas com inconsistência: #{inconsistent_os.count}\n\n"

if inconsistent_os.count == 0
  puts "✓ Nenhuma inconsistência encontrada!"
else
  inconsistent_os.each do |os|
    begin
      proposta_aprovada = os.order_service_proposals.find_by(order_service_proposal_status_id: OrderServiceProposalStatus::APROVADA_ID)
      
      if proposta_aprovada
        old_status = os.order_service_status_id
        
        # Determinar novo status baseado na proposta
        new_status = case proposta_aprovada.order_service_proposal_status_id
        when OrderServiceProposalStatus::APROVADA_ID
          OrderServiceStatus::APROVADA_ID
        when OrderServiceProposalStatus::NOTAS_INSERIDAS_ID
          OrderServiceStatus::NOTA_FISCAL_INSERIDA_ID
        when OrderServiceProposalStatus::AUTORIZADA_ID
          OrderServiceStatus::AUTORIZADA_ID
        when OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID
          OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID
        when OrderServiceProposalStatus::PAGA_ID
          OrderServiceStatus::PAGA_ID
        else
          old_status
        end
        
        if old_status != new_status
          # Atualizar status
          OrderService.where(id: os.id).update_all(order_service_status_id: new_status)
          
          # Gerar histórico
          OrderService.generate_historic(os, admin_user, old_status, new_status) if admin_user
          
          corrected_count += 1
          puts "✓ OS #{os.code} corrigida: #{old_status} → #{new_status}"
        end
      end
    rescue => e
      errors << "OS #{os.code}: #{e.message}"
      puts "✗ Erro ao corrigir OS #{os.code}: #{e.message}"
    end
  end
end

puts "\n=== RESUMO DA CORREÇÃO ==="
puts "Total de OSs corrigidas: #{corrected_count}"
puts "Erros encontrados: #{errors.count}"

if errors.any?
  puts "\nDetalhes dos erros:"
  errors.each { |err| puts "  - #{err}" }
end

puts "\n✓ Correção concluída!"
