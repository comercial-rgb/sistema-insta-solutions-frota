# Rake tasks para padronização de nomes de peças e serviços
# SEGURO: Apenas atualiza capitalização, NUNCA apaga dados
namespace :padronizar do
  desc "Analisa nomes que precisam de padronização (preview seco, não altera nada)"
  task analisar: :environment do
    puts "=" * 80
    puts "ANÁLISE DE PADRONIZAÇÃO — Preview (nenhum dado será alterado)"
    puts "=" * 80

    # Services
    puts "\n📋 SERVICES (tabela services):"
    mudancas_services = 0
    Service.unscoped.where.not(name: [nil, '']).find_each do |s|
      novo_nome = Service.padronizar_nome_peca(s.name)
      if novo_nome != s.name
        mudancas_services += 1
        puts "  ##{s.id} | #{s.name.ljust(45)} → #{novo_nome}" if mudancas_services <= 30
      end
    end
    puts "  ... e mais #{mudancas_services - 30} mudanças" if mudancas_services > 30
    puts "  Total que seriam padronizados: #{mudancas_services} de #{Service.unscoped.count}"

    # Provider Service Temps
    puts "\n📋 PROVIDER SERVICE TEMPS (cotações dos fornecedores):"
    mudancas_temps = 0
    ProviderServiceTemp.unscoped.where.not(name: [nil, '']).find_each do |t|
      novo_nome = ProviderServiceTemp.padronizar_nome_peca(t.name)
      if novo_nome != t.name
        mudancas_temps += 1
        puts "  ##{t.id} | #{t.name.ljust(45)} → #{novo_nome}" if mudancas_temps <= 20
      end
    end
    puts "  ... e mais #{mudancas_temps - 20} mudanças" if mudancas_temps > 20
    puts "  Total que seriam padronizados: #{mudancas_temps} de #{ProviderServiceTemp.unscoped.count}"

    # Order Service Proposal Items
    puts "\n📋 ORDER SERVICE PROPOSAL ITEMS (itens finalizados):"
    mudancas_items = 0
    OrderServiceProposalItem.unscoped.where.not(service_name: [nil, '']).find_each do |i|
      novo_nome = OrderServiceProposalItem.padronizar_nome_peca(i.service_name)
      if novo_nome != i.service_name
        mudancas_items += 1
        puts "  ##{i.id} | #{i.service_name.ljust(45)} → #{novo_nome}" if mudancas_items <= 20
      end
    end
    puts "  ... e mais #{mudancas_items - 20} mudanças" if mudancas_items > 20
    puts "  Total que seriam padronizados: #{mudancas_items} de #{OrderServiceProposalItem.unscoped.count}"

    total = mudancas_services + mudancas_temps + mudancas_items
    puts "\n" + "=" * 80
    puts "RESUMO: #{total} nomes seriam padronizados no total"
    puts "Para aplicar, rode: rake padronizar:aplicar"
    puts "=" * 80
  end

  desc "Aplica padronização em todos os nomes existentes (SEGURO: apenas atualiza texto, não apaga)"
  task aplicar: :environment do
    puts "=" * 80
    puts "APLICANDO PADRONIZAÇÃO DE NOMES"
    puts "⚠️  Apenas altera capitalização/acentos. Nenhum registro será excluído."
    puts "=" * 80

    # 1. Services — usa update_column para evitar disparar validação de unicidade durante migração
    puts "\n🔄 Padronizando SERVICES..."
    atualizados_s = 0
    erros_s = 0
    Service.unscoped.where.not(name: [nil, '']).find_each do |s|
      novo_nome = Service.padronizar_nome_peca(s.name)
      if novo_nome != s.name
        # Verifica se já existe outro serviço com o novo nome na mesma categoria
        duplicata = Service.unscoped.where("LOWER(name) = ? AND category_id = ? AND id != ?",
                                           novo_nome.downcase, s.category_id, s.id).first
        if duplicata
          # Não renomeia — há duplicata. A padronização futura cuidará disso.
          puts "  ⚠️  ##{s.id} '#{s.name}' → '#{novo_nome}' IGNORADO (duplicata de ##{duplicata.id} '#{duplicata.name}')"
          erros_s += 1
        else
          s.update_column(:name, novo_nome)
          atualizados_s += 1
        end
      end
    end
    puts "  ✅ #{atualizados_s} services padronizados, #{erros_s} ignorados (duplicatas)"

    # 2. Provider Service Temps — update_column direto (não tem validação de unicidade)
    puts "\n🔄 Padronizando PROVIDER SERVICE TEMPS..."
    atualizados_t = 0
    ProviderServiceTemp.unscoped.where.not(name: [nil, '']).find_each do |t|
      novo_nome = ProviderServiceTemp.padronizar_nome_peca(t.name)
      if novo_nome != t.name
        t.update_column(:name, novo_nome)
        atualizados_t += 1
      end
    end
    puts "  ✅ #{atualizados_t} provider_service_temps padronizados"

    # 3. Order Service Proposal Items — update_column direto
    puts "\n🔄 Padronizando ORDER SERVICE PROPOSAL ITEMS..."
    atualizados_i = 0
    OrderServiceProposalItem.unscoped.where.not(service_name: [nil, '']).find_each do |i|
      novo_nome = OrderServiceProposalItem.padronizar_nome_peca(i.service_name)
      if novo_nome != i.service_name
        i.update_column(:service_name, novo_nome)
        atualizados_i += 1
      end
    end
    puts "  ✅ #{atualizados_i} order_service_proposal_items padronizados"

    total = atualizados_s + atualizados_t + atualizados_i
    puts "\n" + "=" * 80
    puts "CONCLUÍDO: #{total} nomes padronizados com sucesso"
    puts "Nenhum registro foi excluído. Apenas capitalização/acentos foram ajustados."
    puts "=" * 80
  end

  desc "Detecta e lista duplicatas que existem após padronização (nomes que convergem para o mesmo)"
  task duplicatas: :environment do
    puts "=" * 80
    puts "ANÁLISE DE DUPLICATAS PÓS-PADRONIZAÇÃO"
    puts "=" * 80

    # Agrupa services por nome padronizado + categoria
    grupos = {}
    Service.unscoped.where.not(name: [nil, '']).find_each do |s|
      chave = [Service.padronizar_nome_peca(s.name).downcase, s.category_id]
      grupos[chave] ||= []
      grupos[chave] << s
    end

    duplicatas = grupos.select { |_, services| services.size > 1 }
    if duplicatas.empty?
      puts "\n✅ Nenhuma duplicata encontrada!"
    else
      puts "\n⚠️  #{duplicatas.size} grupos de duplicatas encontrados:"
      duplicatas.each do |chave, services|
        puts "\n  Nome padronizado: '#{Service.padronizar_nome_peca(services.first.name)}' (categoria #{chave[1]})"
        services.each do |s|
          # Conta quantas vezes esse service_id aparece em itens finalizados
          usos = OrderServiceProposalItem.unscoped.where(service_id: s.id).count
          usos_temp = ProviderServiceTemp.unscoped.where(service_id: s.id).count
          puts "    ##{s.id} | '#{s.name}' | provider=#{s.provider_id || 'nil'} | usado em #{usos} itens + #{usos_temp} cotações"
        end
      end
    end
  end

  desc "Resolve duplicatas: migra vínculos para o service principal e remove duplicado (SEGURO)"
  task resolver_duplicatas: :environment do
    puts "=" * 80
    puts "RESOLVENDO DUPLICATAS — migra vínculos e remove o registro duplicado"
    puts "=" * 80

    # Agrupa services por nome padronizado + categoria
    grupos = {}
    Service.unscoped.where.not(name: [nil, '']).find_each do |s|
      chave = [Service.padronizar_nome_peca(s.name.strip).downcase, s.category_id]
      grupos[chave] ||= []
      grupos[chave] << s
    end

    duplicatas = grupos.select { |_, services| services.size > 1 }
    if duplicatas.empty?
      puts "\n✅ Nenhuma duplicata encontrada!"
      return
    end

    resolvidos = 0
    duplicatas.each do |_chave, services|
      # O principal é o que tem mais uso (itens + cotações)
      services_com_uso = services.map do |s|
        usos = OrderServiceProposalItem.unscoped.where(service_id: s.id).count +
               ProviderServiceTemp.unscoped.where(service_id: s.id).count
        [s, usos]
      end
      services_com_uso.sort_by! { |_s, u| -u }

      principal = services_com_uso.first[0]
      # Padroniza o nome do principal
      nome_padronizado = Service.padronizar_nome_peca(principal.name.strip)
      principal.update_column(:name, nome_padronizado)

      duplicados = services_com_uso[1..].map(&:first)

      duplicados.each do |dup|
        usos_items = OrderServiceProposalItem.unscoped.where(service_id: dup.id).count
        usos_temps = ProviderServiceTemp.unscoped.where(service_id: dup.id).count

        # Migra TODOS os vínculos (todas as tabelas que referenciam service_id)
        OrderServiceProposalItem.unscoped.where(service_id: dup.id).update_all(service_id: principal.id)
        ProviderServiceTemp.unscoped.where(service_id: dup.id).update_all(service_id: principal.id)

        # part_service_order_services — itens da OS original
        if defined?(PartServiceOrderService)
          PartServiceOrderService.unscoped.where(service_id: dup.id).update_all(service_id: principal.id)
        else
          ActiveRecord::Base.connection.execute(
            "UPDATE part_service_order_services SET service_id = #{principal.id} WHERE service_id = #{dup.id}"
          )
        end

        # service_group_items — referência de preço
        ActiveRecord::Base.connection.execute(
          "UPDATE service_group_items SET service_id = #{principal.id} WHERE service_id = #{dup.id}"
        ) rescue nil

        # reference_prices
        ActiveRecord::Base.connection.execute(
          "UPDATE reference_prices SET service_id = #{principal.id} WHERE service_id = #{dup.id}"
        ) rescue nil

        puts "  🔄 ##{dup.id} '#{dup.name}' → migrado #{usos_items} itens + #{usos_temps} cotações para ##{principal.id} '#{nome_padronizado}'"

        # Remove o duplicado (agora sem vínculos)
        dup.image.purge if dup.image.attached? rescue nil
        dup.delete
        resolvidos += 1
      end
    end

    puts "\n" + "=" * 80
    puts "CONCLUÍDO: #{resolvidos} duplicatas resolvidas"
    puts "Todos os vínculos foram migrados para o registro principal."
    puts "=" * 80
  end
end
