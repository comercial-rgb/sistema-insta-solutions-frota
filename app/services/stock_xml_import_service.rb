class StockXmlImportService
  attr_reader :xml_file, :client_id, :cost_center_id, :sub_unit_id, :user

  def initialize(xml_file:, client_id:, cost_center_id:, sub_unit_id: nil, user:)
    @xml_file = xml_file
    @client_id = client_id
    @cost_center_id = cost_center_id
    @sub_unit_id = sub_unit_id
    @user = user
  end

  # Parse XML and return preview data without saving
  def parse
    result = { success: false, items: [], errors: [], supplier_name: nil, supplier_cnpj: nil, document_number: nil }

    begin
      xml_content = xml_file.read
      doc = Nokogiri::XML(xml_content) { |config| config.strict.nonet }
      doc.remove_namespaces!

      emit = doc.at_xpath('//emit')
      result[:supplier_name] = extract_text(emit, 'xNome')
      result[:supplier_cnpj] = extract_text(emit, 'CNPJ')
      result[:document_number] = extract_text(doc, '//ide/nNF')
      result[:xml_file_name] = xml_file.respond_to?(:original_filename) ? xml_file.original_filename : 'import.xml'

      items = doc.xpath('//det')
      if items.empty?
        result[:errors] << 'Nenhum item encontrado no XML.'
        return result
      end

      items.each_with_index do |item, idx|
        prod = item.at_xpath('prod')
        next unless prod

        name = extract_text(prod, 'xProd')
        code = extract_text(prod, 'cProd')
        next if name.blank?

        quantity = extract_decimal(prod, 'qCom')
        next if quantity <= 0

        existing = find_existing_item(code, name)

        result[:items] << {
          index: idx,
          name: name,
          code: code,
          ncm: extract_text(prod, 'NCM'),
          unit_measure: (extract_text(prod, 'uCom') || 'UN').upcase,
          quantity: quantity,
          unit_price: extract_decimal(prod, 'vUnCom'),
          brand: extract_text(prod, 'xMarca'),
          existing_id: existing&.id,
          existing_name: existing&.name,
          minimum_quantity: existing&.minimum_quantity || 0,
          parent_stock_item_id: nil
        }
      end

      result[:success] = true
    rescue Nokogiri::XML::SyntaxError => e
      result[:errors] << "XML inválido: #{e.message}"
    rescue StandardError => e
      result[:errors] << "Erro ao processar arquivo: #{e.message}"
    end

    result
  end

  # Confirm import with user-defined minimum_quantity and parent_stock_item_id per item
  def confirm(items_params:, supplier_name:, supplier_cnpj:, document_number:, xml_file_name:)
    result = { success: false, imported: 0, updated: 0, errors: [] }

    begin
      ActiveRecord::Base.transaction do
        items_params.each do |item_data|
          begin
            name = item_data[:name]
            code = item_data[:code]
            quantity = item_data[:quantity].to_f
            unit_price = item_data[:unit_price].to_f
            minimum_quantity = item_data[:minimum_quantity].to_f
            parent_stock_item_id = item_data[:parent_stock_item_id].presence

            next if name.blank? || quantity <= 0

            stock_item = find_existing_item(code, name)

            if stock_item
              stock_item.update(minimum_quantity: minimum_quantity, parent_stock_item_id: parent_stock_item_id) if minimum_quantity > 0 || parent_stock_item_id.present?
              stock_item.add_stock(quantity, user, {
                unit_price: unit_price,
                document_number: document_number,
                supplier_name: supplier_name,
                supplier_cnpj: supplier_cnpj,
                xml_file_name: xml_file_name,
                source: :xml_import,
                reason: "Importação XML - NF #{document_number}"
              })
              stock_item.update(unit_price: unit_price) if unit_price > 0
              result[:updated] += 1
            else
              stock_item = StockItem.create!(
                client_id: client_id,
                cost_center_id: cost_center_id,
                sub_unit_id: sub_unit_id,
                name: name,
                code: code,
                brand: item_data[:brand],
                ncm: item_data[:ncm],
                unit_measure: (item_data[:unit_measure] || 'UN').upcase,
                quantity: quantity,
                unit_price: unit_price,
                minimum_quantity: minimum_quantity,
                parent_stock_item_id: parent_stock_item_id,
                created_by: user,
                status: :active
              )

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
          rescue StandardError => e
            result[:errors] << "Erro no item '#{item_data[:name]}': #{e.message}"
          end
        end
      end

      result[:success] = result[:errors].empty? || result[:imported] > 0 || result[:updated] > 0
    rescue StandardError => e
      result[:errors] << "Erro ao processar importação: #{e.message}"
    end

    result
  end


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
