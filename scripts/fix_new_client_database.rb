# ================================================================
# Script CONSOLIDADO de Correção - Novo Banco do Cliente
# ================================================================
# Este script aplica TODAS as correções necessárias quando receber
# um novo backup do cliente com problemas conhecidos.
#
# Uso: bundle exec rails runner scripts/fix_new_client_database.rb
#
# ⚠️  ATENÇÃO: Faça backup antes de executar!
# ================================================================

require 'benchmark'

puts "\n" + "=" * 70
puts "  CORREÇÃO AUTOMÁTICA - BANCO DO CLIENTE"
puts "=" * 70
puts "Data/Hora: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
puts "=" * 70 + "\n"

# ================================================================
# CONFIGURAÇÕES
# ================================================================

DRY_RUN = false  # Mudar para true para apenas simular sem aplicar

# ================================================================
# ESTATÍSTICAS
# ================================================================

stats = {
  encoding_fixed: 0,
  columns_added: 0,
  status_verified: 0,
  errors: []
}

# ================================================================
# 1. VERIFICAR E ADICIONAR COLUNAS FALTANTES
# ================================================================

def check_and_add_columns(stats)
  puts "\n[1/3] Verificando estrutura do banco..."
  puts "-" * 70
  
  columns_to_add = [
    {
      table: 'order_service_proposals',
      columns: {
        'is_complement' => 'BOOLEAN DEFAULT FALSE',
        'justification' => 'TEXT',
        'reason_refused_approval' => 'TEXT'
      }
    },
    {
      table: 'order_services',
      columns: {
        'service_group_id' => 'BIGINT',
        'origin' => 'VARCHAR(255)'
      }
    },
    {
      table: 'order_service_proposal_items',
      columns: {
        'observation' => 'TEXT',
        'guarantee' => 'VARCHAR(255)',
        'warranty_start_date' => 'DATE'
      }
    },
    {
      table: 'part_service_order_services',
      columns: {
        'quantity' => 'DECIMAL(10,2)'
      }
    },
    {
      table: 'contracts',
      columns: {
        'final_date' => 'DATE'
      }
    }
  ]
  
  columns_to_add.each do |table_config|
    table = table_config[:table]
    
    # Verificar se tabela existe
    unless ActiveRecord::Base.connection.table_exists?(table)
      puts "  ⚠️  Tabela #{table} não existe - pulando..."
      next
    end
    
    existing_columns = ActiveRecord::Base.connection.columns(table).map(&:name)
    
    table_config[:columns].each do |column_name, column_type|
      if existing_columns.include?(column_name)
        puts "  ✓ #{table}.#{column_name} - já existe"
      else
        begin
          sql = "ALTER TABLE #{table} ADD COLUMN #{column_name} #{column_type}"
          puts "  + Adicionando #{table}.#{column_name}..."
          
          unless DRY_RUN
            ActiveRecord::Base.connection.execute(sql)
            stats[:columns_added] += 1
          end
          
          puts "    ✅ Adicionada!"
        rescue => e
          error_msg = "Erro ao adicionar #{table}.#{column_name}: #{e.message}"
          puts "    ❌ #{error_msg}"
          stats[:errors] << error_msg
        end
      end
    end
  end
  
  puts "\n  📊 Colunas adicionadas: #{stats[:columns_added]}"
end

# ================================================================
# 2. CORRIGIR ENCODING
# ================================================================

def fix_encoding_issues(stats)
  puts "\n[2/3] Corrigindo problemas de encoding..."
  puts "-" * 70
  
  # Mapeamento de caracteres corrompidos
  encoding_map = {
    'Ã§Ã£' => 'ção',
    'Ã§' => 'ç',
    'Ã£' => 'ã',
    'Ã©' => 'é',
    'Ã­' => 'í',
    'Ã³' => 'ó',
    'Ãº' => 'ú',
    'Ã ' => 'à',
    'Ã¡' => 'á',
    'Ãª' => 'ê',
    'Ã´' => 'ô',
    'Ã¢' => 'â',
    'Ã' => 'Ã',
    '????' => 'ção',
    '???' => 'ção',
    '??' => 'ção'
  }
  
  # Construir expressão SQL para REPLACE
  def build_replace_chain(column, encoding_map)
    result = column
    encoding_map.each do |wrong, correct|
      result = "REPLACE(#{result}, '#{wrong}', '#{correct}')"
    end
    result
  end
  
  # Tabelas e colunas a corrigir
  tables_to_fix = {
    'users' => ['name', 'corporate_name'],
    'services' => ['name', 'description'],
    'provider_service_types' => ['name', 'description'],
    'contracts' => ['name', 'description'],
    'cost_centers' => ['name', 'description'],
    'commitments' => ['title', 'description'],
    'vehicles' => ['current_owner_name', 'old_owner_name'],
    'notifications' => ['title', 'message'],
    'orientation_manuals' => ['name', 'description']
  }
  
  tables_to_fix.each do |table, columns|
    unless ActiveRecord::Base.connection.table_exists?(table)
      puts "  ⚠️  Tabela #{table} não existe - pulando..."
      next
    end
    
    puts "\n  📋 Processando tabela: #{table}"
    
    columns.each do |column|
      # Verificar se coluna existe
      existing_columns = ActiveRecord::Base.connection.columns(table).map(&:name)
      unless existing_columns.include?(column)
        puts "    ⚠️  Coluna #{column} não existe - pulando..."
        next
      end
      
      # Contar registros com problemas
      count_sql = "SELECT COUNT(*) FROM #{table} WHERE #{column} LIKE '%?%' OR #{column} LIKE '%Ã%'"
      count = ActiveRecord::Base.connection.select_value(count_sql).to_i
      
      if count > 0
        puts "    🔧 #{column}: #{count} registros com problemas"
        
        unless DRY_RUN
          # Aplicar correção
          replace_chain = build_replace_chain(column, encoding_map)
          update_sql = "UPDATE #{table} SET #{column} = #{replace_chain} WHERE #{column} LIKE '%?%' OR #{column} LIKE '%Ã%'"
          
          begin
            ActiveRecord::Base.connection.execute(update_sql)
            stats[:encoding_fixed] += count
            puts "       ✅ Corrigidos!"
          rescue => e
            error_msg = "Erro ao corrigir #{table}.#{column}: #{e.message}"
            puts "       ❌ #{error_msg}"
            stats[:errors] << error_msg
          end
        end
      else
        puts "    ✓ #{column}: OK (sem problemas)"
      end
    end
  end
  
  puts "\n  📊 Total de registros corrigidos: #{stats[:encoding_fixed]}"
end

# ================================================================
# 3. VERIFICAR STATUS
# ================================================================

def verify_status_records(stats)
  puts "\n[3/3] Verificando registros de status..."
  puts "-" * 70
  
  # Verificar se todos os 11 status existem
  required_statuses = {
    1 => 'Em aberto',
    2 => 'Aguardando avaliação de proposta',
    3 => 'Aprovada',
    4 => 'Nota fiscal inserida',
    5 => 'Autorizada',
    6 => 'Aguardando pagamento',
    7 => 'Paga',
    8 => 'Cancelada',
    9 => 'Em cadastro',
    10 => 'Em reavaliação',
    11 => 'Aguardando aprovação de complemento'
  }
  
  missing_ids = []
  
  required_statuses.each do |id, name|
    status = OrderServiceStatus.find_by(id: id)
    if status
      puts "  ✓ Status ID #{id}: #{status.name}"
      stats[:status_verified] += 1
    else
      puts "  ❌ Status ID #{id} faltando: #{name}"
      missing_ids << id
    end
  end
  
  if missing_ids.any?
    puts "\n  ⚠️  ATENÇÃO: #{missing_ids.length} status faltando!"
    puts "  Execute manualmente:"
    missing_ids.each do |id|
      puts "    INSERT INTO order_service_statuses (id, name) VALUES (#{id}, '#{required_statuses[id]}');"
    end
  else
    puts "\n  📊 Todos os status estão corretos!"
  end
end

# ================================================================
# EXECUÇÃO
# ================================================================

if DRY_RUN
  puts "\n⚠️  MODO DE SIMULAÇÃO - Nenhuma alteração será aplicada\n"
end

total_time = Benchmark.measure do
  begin
    ActiveRecord::Base.transaction do
      check_and_add_columns(stats)
      fix_encoding_issues(stats)
      verify_status_records(stats)
      
      if DRY_RUN
        raise ActiveRecord::Rollback
      end
    end
  rescue => e
    puts "\n❌ ERRO CRÍTICO: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    stats[:errors] << "Erro crítico: #{e.message}"
  end
end

# ================================================================
# RELATÓRIO FINAL
# ================================================================

puts "\n" + "=" * 70
puts "  RELATÓRIO FINAL"
puts "=" * 70
puts "Tempo de execução: #{total_time.real.round(2)}s"
puts ""
puts "📊 Estatísticas:"
puts "  - Colunas adicionadas: #{stats[:columns_added]}"
puts "  - Registros com encoding corrigido: #{stats[:encoding_fixed]}"
puts "  - Status verificados: #{stats[:status_verified]}"
puts "  - Erros encontrados: #{stats[:errors].length}"

if stats[:errors].any?
  puts "\n❌ Erros:"
  stats[:errors].each_with_index do |error, i|
    puts "  #{i+1}. #{error}"
  end
end

if DRY_RUN
  puts "\n⚠️  MODO DE SIMULAÇÃO - Execute novamente com DRY_RUN=false para aplicar"
else
  puts "\n✅ Correções aplicadas com sucesso!"
  puts "\n💡 Próximos passos:"
  puts "  1. Reinicie o servidor Rails"
  puts "  2. Teste a aplicação"
  puts "  3. Crie backup do banco corrigido"
end

puts "=" * 70 + "\n"
