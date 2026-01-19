# ================================================================
# Task para Recuperar Peças/Serviços Perdidos em Propostas
# ================================================================
# Uso: rails fix_proposal_items:check
#      rails fix_proposal_items:fix
#
# Descrição: 
# - Identifica propostas que deveriam ter itens mas estão vazias
# - Reconstrói os provider_service_temps baseado na OS original
# ================================================================

namespace :fix_proposal_items do
  
  desc "Verifica propostas com itens faltando"
  task check: :environment do
    puts "\n" + "="*80
    puts "🔍 VERIFICANDO PROPOSTAS COM ITENS FALTANDO"
    puts "="*80 + "\n"
    
    # Buscar propostas em cadastro ou aguardando avaliação
    proposals = OrderServiceProposal.where(
      order_service_proposal_status_id: [
        OrderServiceProposalStatus::EM_CADASTRO_ID,
        OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID
      ]
    )
    
    affected_proposals = []
    
    proposals.each do |proposal|
      os = proposal.order_service
      next unless os
      
      # Contar itens na OS original
      os_items_count = os.part_service_order_services.count
      
      # Contar itens na proposta
      proposal_items_count = proposal.provider_service_temps.count
      
      # Se OS tem itens mas proposta está vazia ou com menos itens
      if os_items_count > 0 && proposal_items_count < os_items_count
        affected_proposals << {
          proposal_id: proposal.id,
          proposal_code: proposal.code,
          os_id: os.id,
          os_code: os.code,
          os_type: os.order_service_type.name,
          expected_items: os_items_count,
          current_items: proposal_items_count,
          missing_items: os_items_count - proposal_items_count,
          provider: proposal.provider&.name || "Sem fornecedor",
          created_at: proposal.created_at.strftime("%d/%m/%Y %H:%M")
        }
      end
    end
    
    if affected_proposals.empty?
      puts "✅ NENHUMA PROPOSTA AFETADA ENCONTRADA!"
      puts "   Todas as propostas estão com os itens corretos.\n\n"
    else
      puts "⚠️  ENCONTRADAS #{affected_proposals.size} PROPOSTA(S) AFETADA(S):\n\n"
      
      affected_proposals.each_with_index do |p, idx|
        puts "#{idx + 1}. Proposta #{p[:proposal_code]} (ID: #{p[:proposal_id]})"
        puts "   OS: #{p[:os_code]} (ID: #{p[:os_id]}) - #{p[:os_type]}"
        puts "   Fornecedor: #{p[:provider]}"
        puts "   Criada em: #{p[:created_at]}"
        puts "   ❌ Itens esperados: #{p[:expected_items]}"
        puts "   ⚠️  Itens atuais: #{p[:current_items]}"
        puts "   🔴 Itens faltando: #{p[:missing_items]}"
        puts ""
      end
      
      puts "="*80
      puts "Para corrigir automaticamente, execute:"
      puts "  rails fix_proposal_items:fix"
      puts "="*80 + "\n\n"
    end
  end
  
  desc "Corrige propostas com itens faltando"
  task fix: :environment do
    puts "\n" + "="*80
    puts "🔧 CORRIGINDO PROPOSTAS COM ITENS FALTANDO"
    puts "="*80 + "\n"
    
    proposals = OrderServiceProposal.where(
      order_service_proposal_status_id: [
        OrderServiceProposalStatus::EM_CADASTRO_ID,
        OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID
      ]
    )
    
    fixed_count = 0
    error_count = 0
    
    proposals.each do |proposal|
      os = proposal.order_service
      next unless os
      
      os_items_count = os.part_service_order_services.count
      proposal_items_count = proposal.provider_service_temps.count
      
      # Pular se já está OK
      next if os_items_count == 0 || proposal_items_count >= os_items_count
      
      begin
        puts "📝 Processando Proposta #{proposal.code} (ID: #{proposal.id})..."
        
        # Buscar IDs dos serviços que já existem na proposta
        existing_service_ids = proposal.provider_service_temps.pluck(:service_id).compact
        
        items_added = 0
        
        # Adicionar itens faltantes
        os.part_service_order_services.each do |ps|
          next unless ps.service.present?
          
          # Pular se já existe
          next if existing_service_ids.include?(ps.service.id)
          
          # Criar provider_service_temp faltante
          proposal.provider_service_temps.create!(
            service_id: ps.service.id,
            name: ps.service.name,
            category_id: ps.service.category_id,
            description: ps.observation || "",
            quantity: ps.quantity || 1,
            price: 0, # Fornecedor precisa preencher
            warranty_period: 30, # Valor padrão mínimo
            brand: "",
            discount: 0,
            total_value: 0
          )
          
          items_added += 1
        end
        
        if items_added > 0
          puts "   ✅ Adicionados #{items_added} item(ns)"
          fixed_count += 1
        else
          puts "   ℹ️  Nenhum item novo adicionado"
        end
        
      rescue => e
        puts "   ❌ Erro: #{e.message}"
        error_count += 1
      end
    end
    
    puts "\n" + "="*80
    puts "📊 RESULTADO:"
    puts "   ✅ Propostas corrigidas: #{fixed_count}"
    puts "   ❌ Erros: #{error_count}"
    puts "="*80 + "\n\n"
    
    if fixed_count > 0
      puts "⚠️  ATENÇÃO:"
      puts "   Os itens foram adicionados com valores padrão (preço = 0)"
      puts "   Os fornecedores precisam acessar e preencher os preços!"
      puts ""
    end
  end
  
  desc "Lista todas as propostas em cadastro"
  task list: :environment do
    puts "\n" + "="*80
    puts "📋 PROPOSTAS EM CADASTRO"
    puts "="*80 + "\n"
    
    proposals = OrderServiceProposal.where(
      order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID
    )
    
    if proposals.empty?
      puts "Nenhuma proposta em cadastro encontrada.\n\n"
    else
      proposals.each do |proposal|
        os = proposal.order_service
        items_count = proposal.provider_service_temps.count
        os_items_count = os&.part_service_order_services&.count || 0
        
        status_icon = items_count >= os_items_count ? "✅" : "⚠️"
        
        puts "#{status_icon} Proposta: #{proposal.code} (ID: #{proposal.id})"
        puts "   OS: #{os&.code} - #{os&.order_service_type&.name}"
        puts "   Fornecedor: #{proposal.provider&.name}"
        puts "   Itens: #{items_count}/#{os_items_count}"
        puts ""
      end
    end
    
    puts "="*80 + "\n\n"
  end
  
end
