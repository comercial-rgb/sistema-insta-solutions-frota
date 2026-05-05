# lib/tasks/catalogo_pecas.rake
# Tarefas para gerenciar catálogo de peças importado de PDFs
#
# Uso:
#   rake catalogo:import          - Importa todos os PDFs pendentes da pasta catalogo_pdf/
#   rake catalogo:import_all      - Reimporta TODOS os PDFs (limpa dados anteriores)
#   rake catalogo:stats           - Mostra estatísticas do catálogo
#   rake catalogo:normalizar      - Normaliza nomes de serviços/peças usando o catálogo

namespace :catalogo do
  desc "Importa PDFs pendentes da pasta catalogo_pdf/"
  task import: :environment do
    pasta = Rails.root.join('catalogo_pdf')
    python_script = pasta.join('importar_catalogos.py')

    unless File.exist?(python_script)
      puts "Script de importação não encontrado: #{python_script}"
      next
    end

    # Detecta PDFs na pasta
    pdfs = Dir.glob(pasta.join('*.pdf'))
    if pdfs.empty?
      puts "Nenhum PDF encontrado em #{pasta}"
      next
    end

    puts "="*60
    puts "IMPORTAÇÃO DE CATÁLOGOS PDF"
    puts "="*60
    puts "PDFs encontrados: #{pdfs.count}"

    pdfs_para_importar = []

    pdfs.each do |pdf_path|
      filename = File.basename(pdf_path)
      checksum = Digest::MD5.file(pdf_path).hexdigest

      registro = CatalogoPdfImport.find_by(filename: filename)

      if registro&.processado? && registro.checksum == checksum
        puts "  [OK] #{filename} — já importado (#{registro.total_registros} registros)"
      else
        fornecedor = detectar_fornecedor(filename)
        pdfs_para_importar << { path: pdf_path, filename: filename, fornecedor: fornecedor, checksum: checksum }
        puts "  [NOVO] #{filename} → fornecedor: #{fornecedor}"
      end
    end

    if pdfs_para_importar.empty?
      puts "\nTodos os PDFs já estão importados!"
      next
    end

    puts "\nImportando #{pdfs_para_importar.count} PDF(s)..."

    # Roda o script Python para cada PDF pendente
    pdfs_para_importar.each do |pdf|
      puts "\n→ Processando: #{pdf[:filename]} (#{pdf[:fornecedor]})"

      registro = CatalogoPdfImport.find_or_initialize_by(filename: pdf[:filename])
      registro.fornecedor = pdf[:fornecedor]
      registro.checksum = pdf[:checksum]
      registro.status = 'processando'
      registro.save!

      begin
        # Executa o script Python passando o arquivo e fornecedor como argumentos
        result = system(
          "python", python_script.to_s,
          "--arquivo", pdf[:path],
          "--fornecedor", pdf[:fornecedor],
          "--db-host", db_config['host'] || '127.0.0.1',
          "--db-port", (db_config['port'] || 3306).to_s,
          "--db-name", db_config['database'],
          "--db-user", db_config['username'] || 'root',
          "--db-pass", db_config['password'] || ''
        )

        if result
          total = CatalogoPeca.where(fornecedor: pdf[:fornecedor]).count
          registro.marcar_processado!(total_registros: total, total_paginas: 0)
          puts "  Importado com sucesso! #{total} registros no catálogo."
        else
          registro.marcar_erro!("Script Python retornou erro")
          puts "  ERRO na importação!"
        end
      rescue => e
        registro.marcar_erro!(e.message)
        puts "  ERRO: #{e.message}"
      end
    end

    puts "\n" + "="*60
    puts "IMPORTAÇÃO CONCLUÍDA"
    puts "Total de registros no catálogo: #{CatalogoPeca.count}"
    puts "="*60
  end

  desc "Reimporta TODOS os PDFs (limpa dados anteriores)"
  task import_all: :environment do
    puts "Limpando catálogo existente..."
    CatalogoPeca.delete_all
    CatalogoPdfImport.delete_all
    puts "Catálogo limpo!"
    Rake::Task['catalogo:import'].invoke
  end

  desc "Mostra estatísticas do catálogo"
  task stats: :environment do
    puts "="*60
    puts "ESTATÍSTICAS DO CATÁLOGO DE PEÇAS"
    puts "="*60

    unless CatalogoPeca.table_exists?
      puts "Tabela catalogo_pecas não existe. Rode: rails db:migrate"
      next
    end

    total = CatalogoPeca.count
    puts "Total de registros: #{total}"

    if total > 0
      puts "\nPor fornecedor:"
      CatalogoPeca.group(:fornecedor).count.sort_by { |_, v| -v }.each do |fornecedor, count|
        puts "  #{fornecedor}: #{count} registros"
      end

      puts "\nMarcas com mais registros:"
      CatalogoPeca.group(:marca).count.sort_by { |_, v| -v }.first(15).each do |marca, count|
        puts "  #{marca}: #{count}"
      end

      puts "\nGrupos de produto:"
      CatalogoPeca.group(:grupo_produto).count.sort_by { |_, v| -v }.first(20).each do |grupo, count|
        puts "  #{grupo.to_s.gsub("\n", " ")}: #{count}"
      end
    end

    puts "\nPDFs importados:"
    CatalogoPdfImport.all.each do |pdf|
      puts "  #{pdf.filename} — #{pdf.status} (#{pdf.total_registros} registros)"
    end
  end

  desc "Normaliza nomes de serviços/peças existentes usando o catálogo (algoritmo inteligente)"
  task normalizar: :environment do
    puts "="*60
    puts "NORMALIZAÇÃO DE NOMES DE PEÇAS"
    puts "="*60

    unless CatalogoPeca.table_exists? && CatalogoPeca.count > 0
      puts "Catálogo vazio. Importe os PDFs primeiro: rake catalogo:import"
      next
    end

    puts "Grupos de produto no catálogo: #{CatalogoPeca.distinct.pluck(:grupo_produto).reject(&:blank?).count}"

    # Busca serviços do tipo peça
    pecas = Service.where(category_id: Category::SERVICOS_PECAS_ID)
    puts "Peças no sistema: #{pecas.count}"

    sugestoes = []

    pecas.find_each do |peca|
      match = CatalogoPeca.normalizar_nome_inteligente(peca.name)
      if match != peca.name
        sugestoes << { id: peca.id, nome_atual: peca.name, nome_catalogo: match }
      end
    end

    if sugestoes.empty?
      puts "\nTodas as peças já estão com nomes padronizados!"
    else
      puts "\n#{sugestoes.count} peças podem ser normalizadas:"
      sugestoes.each_with_index do |s, i|
        puts "  #{i+1}. '#{s[:nome_atual]}' → '#{s[:nome_catalogo]}'"
      end

      puts "\nPara aplicar, rode: rake catalogo:normalizar_aplicar"
    end
  end

  desc "Aplica normalização de nomes (após revisar com rake catalogo:normalizar)"
  task normalizar_aplicar: :environment do
    pecas = Service.where(category_id: Category::SERVICOS_PECAS_ID)
    atualizados = 0

    pecas.find_each do |peca|
      match = CatalogoPeca.normalizar_nome_inteligente(peca.name)

      if match != peca.name
        # Verifica se o nome novo já não existe
        conflito = Service.where("LOWER(name) = ? AND category_id = ? AND id != ?",
          match.downcase, peca.category_id, peca.id).exists?

        if conflito
          puts "  CONFLITO: '#{peca.name}' → '#{match}' (já existe)"
        else
          old_name = peca.name
          peca.update_column(:name, match)
          atualizados += 1
          puts "  OK: '#{old_name}' → '#{match}'"
        end
      end
    end

    puts "\n#{atualizados} peças normalizadas!"
  end

  private

  def detectar_fornecedor(filename)
    nome = filename.downcase
    case nome
    when /controil/ then 'CONTROIL'
    when /lonaflex/ then 'LONAFLEX'
    when /frasle|fras-le/ then 'FRASLE'
    when /fremax/ then 'FREMAX'
    when /nakata/ then 'NAKATA'
    when /mahle/ then 'MAHLE'
    when /gates/ then 'GATES'
    when /monroe/ then 'MONROE'
    when /trw/ then 'TRW'
    when /bosch/ then 'BOSCH'
    when /denso/ then 'DENSO'
    when /sachs/ then 'SACHS'
    when /wega/ then 'WEGA'
    when /mann/ then 'MANN'
    when /skf/ then 'SKF'
    else
      # Extrai nome do fornecedor do filename
      nome.gsub(/^pdf[_\s-]*/, '').gsub(/[-_]bra.*$/, '').gsub(/\d+/, '').strip.upcase
    end
  end

  def db_config
    @db_config ||= ActiveRecord::Base.connection_db_config.configuration_hash.stringify_keys
  end
end
