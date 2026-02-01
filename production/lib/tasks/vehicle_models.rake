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
