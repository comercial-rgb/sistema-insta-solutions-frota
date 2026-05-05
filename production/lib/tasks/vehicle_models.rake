namespace :vehicle_models do
  desc "Lista todos os modelos únicos de veículos cadastrados (para criar VehicleModels)"
  task list_unique_models: :environment do
    puts "\n=========================================="
    puts "MODELOS ÚNICOS DE VEÍCULOS NO SISTEMA"
    puts "==========================================\n"
    
    # Agrupa por tipo de veículo e modelo
    Vehicle.where.not(model: [nil, '']).group(:vehicle_type_id, :model).count.sort_by { |k, v| [-v, k[0].to_i, k[1]] }.each do |(type_id, model), count|
      vehicle_type = VehicleType.find_by(id: type_id)
      type_name = vehicle_type ? vehicle_type.name : "Sem tipo"
      
      puts "#{count.to_s.rjust(4)}x | #{type_name.ljust(20)} | #{model}"
    end
    
    total = Vehicle.where.not(model: [nil, '']).count
    unique = Vehicle.where.not(model: [nil, '']).distinct.count(:model)
    
    puts "\n=========================================="
    puts "Total de veículos: #{total}"
    puts "Modelos únicos: #{unique}"
    puts "==========================================\n"
  end

  desc "Tenta vincular automaticamente todos os veículos existentes aos VehicleModels"
  task auto_link_all: :environment do
    puts "\n=========================================="
    puts "AUTO-VINCULAÇÃO DE VEÍCULOS"
    puts "==========================================\n"
    
    vehicles_without_model = Vehicle.where(vehicle_model_id: nil).where.not(model: [nil, ''])
    total = vehicles_without_model.count
    linked = 0
    not_linked = 0
    
    puts "Processando #{total} veículos...\n"
    
    vehicles_without_model.find_each.with_index do |vehicle, index|
      if vehicle.try_auto_link_vehicle_model
        linked += 1
        print "✓"
      else
        not_linked += 1
        print "·"
      end
      
      # Nova linha a cada 50 veículos
      puts " #{index + 1}/#{total}" if (index + 1) % 50 == 0
    end
    
    puts "\n\n=========================================="
    puts "RESULTADO:"
    puts "  Vinculados: #{linked}"
    puts "  Não vinculados: #{not_linked}"
    puts "  Total processado: #{total}"
    puts "==========================================\n"
  end

  desc "Exporta modelos únicos para CSV (para importação em massa)"
  task export_unique_to_csv: :environment do
    require 'csv'
    
    filename = "tmp/vehicle_models_import_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
    
    CSV.open(filename, 'wb', write_headers: true, headers: ['vehicle_type_id', 'brand', 'model', 'full_name', 'count']) do |csv|
      Vehicle.where.not(model: [nil, '']).group(:vehicle_type_id, :model).count.sort_by { |k, v| [-v] }.each do |(type_id, model), count|
        # Tenta extrair marca do texto (primeiro palavra geralmente é a marca)
        parts = model.split(' ')
        brand = parts.first || ''
        model_name = parts[1..-1].join(' ') if parts.length > 1
        
        csv << [type_id, brand, model_name, model, count]
      end
    end
    
    puts "\n✓ Arquivo CSV criado: #{filename}"
    puts "  Use este arquivo para revisar e criar VehicleModels em massa\n"
  end

  desc "Vinculação inteligente: matching flexível brand+modelo (DRY_RUN=1 para simular)"
  task smart_link: :environment do
    dry_run = ENV['DRY_RUN'] == '1'
    
    puts "\n=========================================="
    puts dry_run ? "  SMART LINK (DRY RUN - sem alterações)" : "  SMART LINK - Vinculação Inteligente"
    puts "==========================================\n"
    
    # Cache de todos os VehicleModels ativos
    all_models = VehicleModel.active.to_a
    
    unlinked = Vehicle.unscoped.where(vehicle_model_id: nil)
                       .where.not(brand: [nil, ''])
                       .where.not(model: [nil, ''])
    total = unlinked.count
    linked = 0
    not_linked = 0
    unmatched = []
    
    puts "Processando #{total} veículos sem vínculo...\n"
    
    unlinked.find_each.with_index do |vehicle, index|
      brand_norm = vehicle.brand.to_s.upcase.strip
      model_norm = vehicle.model.to_s.upcase.strip
      
      vm = nil
      
      # 1) Match exato: brand + VehicleModel.model contido no Vehicle.model
      vm = all_models.find do |candidate|
        candidate.brand.to_s.upcase.strip == brand_norm &&
          model_norm.include?(candidate.model.to_s.upcase.strip) &&
          candidate.model.to_s.strip.length > 2
      end
      
      # 2) Match por full_name normalizado contido no "BRAND MODEL" do veículo
      unless vm
        vehicle_full = "#{brand_norm} #{model_norm}"
        vm = all_models.find do |candidate|
          cand_full = "#{candidate.brand} #{candidate.model}".upcase.strip
          cand_full.length > 4 && vehicle_full.include?(cand_full)
        end
      end
      
      # 3) Match sem brand - modelo do VehicleModel contido no modelo do veículo
      unless vm
        vm = all_models.find do |candidate|
          cand_model = candidate.model.to_s.upcase.strip
          cand_model.length > 5 && model_norm.include?(cand_model)
        end
      end
      
      if vm
        unless dry_run
          vehicle.update_column(:vehicle_model_id, vm.id)
        end
        linked += 1
        print "✓"
      else
        not_linked += 1
        unmatched << { id: vehicle.id, board: vehicle.board, brand: brand_norm, model: model_norm } if unmatched.size < 30
        print "·"
      end
      
      puts " #{index + 1}/#{total}" if (index + 1) % 50 == 0
    end
    
    puts "\n\n=========================================="
    puts "RESULTADO#{' (DRY RUN)' if dry_run}:"
    puts "  Vinculados: #{linked}"
    puts "  Sem match: #{not_linked}"
    puts "  Total: #{total}"
    if total > 0
      puts "  Taxa: #{(linked.to_f / total * 100).round(1)}%"
    end
    puts "==========================================\n"
    
    if unmatched.any?
      puts "\nVeículos sem match (#{[unmatched.size, 30].min} primeiros):"
      unmatched.each do |v|
        puts "  ID:#{v[:id]} | #{v[:board]} | #{v[:brand]} | #{v[:model]}"
      end
    end
    
    if dry_run
      puts "\n⚠️  DRY RUN - nenhuma alteração foi feita."
      puts "Execute sem DRY_RUN=1 para aplicar: rake vehicle_models:smart_link"
    end
  end

  desc "Mostra estatísticas de vinculação"
  task stats: :environment do
    total_vehicles = Vehicle.count
    with_model_text = Vehicle.where.not(model: [nil, '']).count
    linked = Vehicle.where.not(vehicle_model_id: nil).count
    not_linked = with_model_text - linked
    
    total_vehicle_models = VehicleModel.where(active: true).count
    
    puts "\n=========================================="
    puts "ESTATÍSTICAS DE VINCULAÇÃO"
    puts "==========================================\n"
    puts "Veículos cadastrados: #{total_vehicles}"
    puts "  Com texto no modelo: #{with_model_text}"
    puts "  Vinculados a VehicleModel: #{linked}"
    puts "  Não vinculados: #{not_linked}"
    puts "\nModelos de Veículos criados: #{total_vehicle_models}"
    
    if with_model_text > 0
      percentage = (linked.to_f / with_model_text * 100).round(1)
      puts "\nTaxa de vinculação: #{percentage}%"
    end
    
    puts "==========================================\n"
  end
end
