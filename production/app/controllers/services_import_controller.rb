class ServicesImportController < ApplicationController
  require 'csv'
  
  before_action :authorize_import
  
  def new
    # Formulário de upload
  end
  
  def create
    return redirect_to new_services_import_path, alert: 'Nenhum arquivo selecionado' unless params[:file].present?
    
    file = params[:file]
    return redirect_to new_services_import_path, alert: 'Formato inválido. Use CSV ou Excel (.xlsx)' unless valid_file_format?(file)
    
    begin
      # Processar arquivo
      results = process_import_file(file)
      
      flash[:success] = "Importação concluída! #{results[:success]} itens criados, #{results[:updated]} atualizados, #{results[:errors]} com erro."
      redirect_to services_path
      
    rescue => e
      Rails.logger.error "Erro na importação: #{e.message}"
      flash[:error] = "Erro ao processar arquivo: #{e.message}"
      redirect_to new_services_import_path
    end
  end
  
  def template
    # Gerar arquivo template para download
    csv_data = generate_template_csv
    
    send_data csv_data,
      filename: "template_importacao_pecas_servicos_#{Date.today.strftime('%Y%m%d')}.csv",
      type: 'text/csv',
      disposition: 'attachment'
  end
  
  private
  
  def authorize_import
    authorize Service, :create?
  end
  
  def valid_file_format?(file)
    ['text/csv', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'].include?(file.content_type) ||
    file.original_filename.match?(/\.(csv|xlsx|xls)$/i)
  end
  
  def process_import_file(file)
    results = { success: 0, updated: 0, errors: 0, error_details: [] }
    
    # Ler CSV
    csv_content = if file.original_filename.match?(/\.csv$/i)
      file.read.force_encoding('UTF-8')
    else
      # Para Excel, precisaria da gem roo ou creek
      # Por enquanto, vamos focar em CSV
      return results.merge(errors: 1, error_details: ['Apenas arquivos CSV são suportados no momento'])
    end
    
    CSV.parse(csv_content, headers: true, col_sep: detect_separator(csv_content)) do |row|
      next if row.to_h.values.all?(&:blank?) # Pular linhas vazias
      
      begin
        process_row(row, results)
      rescue => e
        results[:errors] += 1
        results[:error_details] << "Linha #{row.to_h}: #{e.message}"
      end
    end
    
    results
  end
  
  def process_row(row, results)
    # Estrutura esperada do CSV:
    # nome, categoria, codigo, preco
    
    name = row['nome']&.strip
    category_name = row['categoria']&.strip&.downcase
    code = row['codigo']&.strip
    price_str = row['preco']&.strip
    
    # Validações básicas
    raise 'Nome é obrigatório' if name.blank?
    raise 'Categoria é obrigatória (peca ou servico)' if category_name.blank?
    
    # Determinar category_id
    category_id = case category_name
    when 'peca', 'peça', 'pecas', 'peças'
      Category::SERVICOS_PECAS_ID
    when 'servico', 'serviço', 'servicos', 'serviços'
      Category::SERVICOS_SERVICOS_ID
    else
      raise "Categoria inválida: #{category_name}. Use 'peca' ou 'servico'"
    end
    
    # Parse do preço
    price = parse_currency(price_str)
    
    # Buscar serviço existente por nome e categoria
    service = Service.find_by('LOWER(name) = ? AND category_id = ?', name.downcase, category_id)
    
    if service
      # Atualizar existente (apenas se código ou preço forem diferentes)
      updated = false
      if code.present? && service.code != code
        service.code = code
        updated = true
      end
      if price.present? && service.price != price
        service.price = price
        updated = true
      end
      
      if updated
        service.save!
        results[:updated] += 1
      else
        # Registro já existe com os mesmos dados, não faz nada
        results[:success] += 1
      end
    else
      # Criar novo serviço
      provider_id = @current_user.provider? ? @current_user.id : nil
      
      Service.create!(
        name: name,
        category_id: category_id,
        code: code,
        price: price || 0,
        provider_id: provider_id
      )
      results[:success] += 1
    end
  end
  
  def parse_currency(value)
    return nil if value.blank?
    # Remover símbolos e converter para decimal
    # Aceita formatos: 45,50 ou 45.50 ou R$ 45,50
    cleaned = value.to_s.gsub(/[^\d,.]/, '')
    
    # Se tiver vírgula, assumir formato brasileiro (45,50)
    if cleaned.include?(',')
      cleaned.gsub('.', '').gsub(',', '.').to_f
    else
      # Se só tiver ponto, formato americano (45.50)
      cleaned.to_f
    end
  end
  
  def detect_separator(csv_content)
    # Detectar separador (; ou ,)
    first_line = csv_content.lines.first
    first_line.count(';') > first_line.count(',') ? ';' : ','
  end
  
  def generate_template_csv
    CSV.generate(col_sep: ';', encoding: 'UTF-8') do |csv|
      # Cabeçalho (apenas campos essenciais)
      csv << ['nome', 'categoria', 'codigo', 'preco']
      
      # Exemplos
      csv << ['Filtro de Óleo', 'peca', 'FO-001', '45,50']
      csv << ['Filtro de Ar', 'peca', 'FA-001', '38,90']
      csv << ['Pastilha de Freio Dianteira', 'peca', 'PF-001', '89,00']
      csv << ['Mão de Obra Troca de Óleo', 'servico', 'MO-001', '50,00']
      csv << ['Alinhamento e Balanceamento', 'servico', 'AB-001', '80,00']
    end
  end
end
