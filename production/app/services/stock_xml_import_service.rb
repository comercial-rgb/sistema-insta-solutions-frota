class StockXmlImportService
  attr_reader :xml_file, :client_id, :cost_center_id, :sub_unit_id, :user

  def initialize(xml_file:, client_id:, cost_center_id:, sub_unit_id: nil, user:)
    @xml_file = xml_file
    @client_id = client_id
    @cost_center_id = cost_center_id
    @sub_unit_id = sub_unit_id
    @user = user
  end

  def call
    result = { success: false, imported: 0, updated: 0, errors: [] }

    begin
      xml_content = xml_file.read
      doc = Nokogiri::XML(xml_content) { |config| config.strict.nonet }

      # Remove namespaces para facilitar a navegação
      doc.remove_namespaces!

      # Extrair dados do emitente (fornecedor)
      emit = doc.at_xpath('//emit')
      supplier_name = extract_text(emit, 'xNome')
      supplier_cnpj = extract_text(emit, 'CNPJ')
      document_number = extract_text(doc, '//ide/nNF')
      xml_file_name = xml_file.respond_to?(:original_filename) ? xml_file.original_filename : 'import.xml'

      # Processar cada item da nota
      items = doc.xpath('//det')

      if items.empty?
        result[:errors] << 'Nenhum item encontrado no XML.'
        return result
      end

      ActiveRecord::Base.transaction do
        items.each do |item|
          begin
            process_item(item, supplier_name, supplier_cnpj, document_number, xml_file_name, result)
          rescue StandardError => e
            prod = item.at_xpath('prod')
            item_name = extract_text(prod, 'xProd') rescue 'Desconhecido'
            result[:errors] << "Erro no item '#{item_name}': #{e.message}"
          end
        end
      end

      result[:success] = result[:errors].empty? || result[:imported] > 0 || result[:updated] > 0
    rescue Nokogiri::XML::SyntaxError => e
      result[:errors] << "XML inválido: #{e.message}"
    rescue StandardError => e
      result[:errors] << "Erro ao processar arquivo: #{e.message}"
    end

    result
  end

  private

  def process_item(item_node, supplier_name, supplier_cnpj, document_number, xml_file_name, result)
    prod = item_node.at_xpath('prod')
    return unless prod

    name = extract_text(prod, 'xProd')
    code = extract_text(prod, 'cProd')
    ncm = extract_text(prod, 'NCM')
    unit_measure = extract_text(prod, 'uCom') || 'UN'
    quantity = extract_decimal(prod, 'qCom')
    unit_price = extract_decimal(prod, 'vUnCom')
    brand = extract_text(prod, 'xMarca')

    return if name.blank? || quantity <= 0

    # Procurar item existente por código ou nome no mesmo centro de custo
    stock_item = find_existing_item(code, name)

    if stock_item
      # Atualizar estoque existente (adicionar quantidade)
      stock_item.add_stock(quantity, user, {
        unit_price: unit_price,
        document_number: document_number,
        supplier_name: supplier_name,
        supplier_cnpj: supplier_cnpj,
        xml_file_name: xml_file_name,
        source: :xml_import,
        reason: "Importação XML - NF #{document_number}"
      })

      # Atualizar preço unitário se fornecido
      stock_item.update(unit_price: unit_price) if unit_price > 0

      result[:updated] += 1
    else
      # Criar novo item de estoque
      stock_item = StockItem.create!(
        client_id: client_id,
        cost_center_id: cost_center_id,
        sub_unit_id: sub_unit_id,
        name: name,
        code: code,
        brand: brand,
        ncm: ncm,
        unit_measure: unit_measure.upcase,
        quantity: quantity,
        unit_price: unit_price,
        created_by: user,
        status: :active
      )

      # Registrar movimento de entrada
      stock_item.stock_movements.create!(
        user: user,
        movement_type: :entry,
        quantity: quantity,
        unit_price: unit_price,
        balance_after: quantity,
        reason: "Importação XML - NF #{document_number}",
        document_number: document_number,
        supplier_name: supplier_name,
        supplier_cnpj: supplier_cnpj,
        xml_file_name: xml_file_name,
        source: :xml_import
      )

      result[:imported] += 1
    end
  end

  def find_existing_item(code, name)
    scope = StockItem.where(client_id: client_id, cost_center_id: cost_center_id)
    scope = scope.where(sub_unit_id: sub_unit_id) if sub_unit_id.present?

    # Primeiro tenta pelo código
    if code.present?
      item = scope.find_by(code: code)
      return item if item
    end

    # Depois tenta pelo nome exato
    scope.find_by("LOWER(name) = ?", name.downcase.strip)
  end

  def extract_text(node, xpath)
    return nil unless node
    element = node.at_xpath(xpath)
    element&.text&.strip
  end

  def extract_decimal(node, xpath)
    text = extract_text(node, xpath)
    return 0.0 if text.blank?
    text.gsub(',', '.').to_f
  end
end
