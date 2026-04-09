require 'zip'
require 'fileutils'

# NÃO usa mais docx_replace devido a problemas de File.rename no Windows
# Manipula o DOCX diretamente como arquivo ZIP

module Utils
  module OrderServices
    class GenerateInvoiceDocxService
      def initialize(order_services, client, current_month, invoice_split: nil, bank_account: nil)
        @order_services = order_services
        @client = client
        @current_month = current_month
        @invoice_split = invoice_split # nil = all, 'parts' = only parts, 'services' = only services
        @bank_account = bank_account
        @order_service_invoices = []
      end

      def call
        # WINDOWS FIX: Cria no diretório public/ onde já temos permissão garantida
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_gerada_#{timestamp}_#{SecureRandom.hex(4)}.docx"
        output_path = Rails.root.join('public', output_filename)
        
        # Limpa faturas antigas (mais de 1 hora)
        cleanup_old_invoices
        
        values = getting_values_by_proposals
        values = values.transform_values { |v| v.respond_to?(:to_f) ? v.to_f : v.inspect }

        # Determine the appropriate template size based on invoice count
        @template_size = case @order_service_invoices.length
                when 0..50
                  50
                when 51..75
                  75
                when 76..100
                  100
                when 101..125
                  125
                when 126..150
                  150
                when 151..175
                  175
                when 176..200
                  200
                when 201..225
                  225
                when 226..250
                  250
                when 251..275
                  275
                when 276..300
                  300
                else
                  300 # Default to largest template if exceeds 300
                end

        template_path = Rails.root.join('public', 'fatura_'+@template_size.to_s+'.docx')
        raise "Template não encontrado em #{template_path}" unless File.exist?(template_path)

        # Preparar todas as substituições
        replacements = {}
        
        # Valores financeiros
        replacements['VALORTOTAL'] = CustomHelper.to_currency(values[:valortotal])
        replacements['DESCONTOIR'] = CustomHelper.to_currency(values[:descontoir])
        replacements['VALORBRUTO'] = CustomHelper.to_currency(values[:valorbruto])
        replacements['DISCOUNT'] = CustomHelper.to_currency(values[:desconto])
        replacements['VALORDESCONTO'] = CustomHelper.to_currency(values[:valorcomdesconto])
        
        # Retenções por esfera (municipal/estadual: 5,45% peças, 9,45% serviços para não-simples)
        replacements['RETENCAOESFERA'] = CustomHelper.to_currency(values[:retencao_esfera])
        
        # Dados do cliente
        cost_centers_name = @order_services.map { |os| os.cost_center&.name }.compact.uniq.join(' / ')
        replacements['NOMECLIENTE'] = @client.social_name || ''
        replacements['CENTRODECUSTO'] = cost_centers_name
        replacements['CNPJCLIENTE'] = @client.cnpj || ''
        replacements['ENDERECOCLIENTE'] = @client.get_address || ''
        replacements['CIDADECLIENTE'] = @client.get_city || ''
        replacements['ESTADOCLIENTE'] = @client.get_state || ''
        replacements['TELEFONECLIENTE'] = @client.phone || ''
        replacements['EMAILCLIENTE'] = @client.email || ''
        replacements['ESFERACLIENTE'] = @client.sphere_name
        
        # Desconto do cliente (percentual real, não fixo)
        client_discount = @client.discount_percent || 0
        replacements['PERCENTUALDESCONTO'] = "#{CustomHelper.to_currency(client_discount)} %"
        
        # Contrato e Empenho (pega do primeiro OS que tiver)
        first_os_with_commitment = @order_services.find { |os| os.commitment_parts_id.present? || os.commitment_services_id.present? }
        commitment = nil
        if first_os_with_commitment
          commitment = Commitment.find_by(id: first_os_with_commitment.commitment_parts_id) || 
                       Commitment.find_by(id: first_os_with_commitment.commitment_services_id)
        end
        replacements['NUMEROEMPENHO'] = commitment&.commitment_number || ''
        replacements['NUMEROCONTRATO'] = commitment&.contract&.number || ''
        
        # Nosso número (aleatório)
        replacements['NOSSONUMERO'] = SecureRandom.random_number(100000000).to_s.rjust(8, '0')
        
        # Conta bancária
        if @bank_account
          bank_info = "#{@bank_account.bank&.name} | Ag: #{@bank_account.agency} | CC: #{@bank_account.account}"
          bank_info += " | Op: #{@bank_account.operation}" if @bank_account.operation.present?
          bank_info += " | PIX: #{@bank_account.pix}" if @bank_account.pix.present?
          bank_info += " | CPF/CNPJ: #{@bank_account.cpf_cnpj}" if @bank_account.cpf_cnpj.present?
          replacements['CONTABANCARIA'] = bank_info
        else
          replacements['CONTABANCARIA'] = ''
        end
        
        # Datas
        vencimento = (@current_month.last + 1.month)
        replacements['DATAVENCIMENTO'] = CustomHelper.get_text_date(vencimento, 'date', :default)
        replacements['INICIOFATURA'] = CustomHelper.get_text_date(@current_month.first, 'date', :default)
        replacements['FIMFATURA'] = CustomHelper.get_text_date(@current_month.last, 'date', :default)
        replacements['DATADOCUMENTO'] = CustomHelper.get_text_date(Date.today, 'date', :default)
        
        # Adicionar substituições da tabela de despesas
        add_expense_table_replacements(replacements)
        
        # NOVA ABORDAGEM: Manipula DOCX diretamente usando RubyZip
        # Sem usar docx_replace que tem problemas de File.rename no Windows
        generate_docx_without_rename(template_path, output_path, replacements)

        # Retorna o caminho do arquivo gerado
        output_path.to_s
      end

      private

      def add_expense_table_replacements(replacements)
        @order_service_invoices.each_with_index do |e, index|
          index_str = index < 9 ? "0#{index+1}" : (index+1).to_s
          
          irvalue = 0
          if e.order_service_proposal.provider.optante_simples
            if e.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID
              irvalue = e.value * 0.012
            else
              irvalue = e.value * 0.048
            end
          end
          
          description = e.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID ? 
                        "Aquisição de Peças" : "Prestação de Serviços"
          
          replacements["#{index_str}DATA"] = e.emission_date.strftime('%d/%m')
          replacements["#{index_str}DESCRICAO"] = description
          replacements["#{index_str}VALOR"] = CustomHelper.to_currency(e.value)
          replacements["#{index_str}NOTA"] = e.number.to_s
          replacements["#{index_str}IR"] = CustomHelper.to_currency(irvalue)
          replacements["#{index_str}FORNECEDOR"] = e.order_service_proposal.provider.get_name || ''
          replacements["#{index_str}CNPJ"] = e.order_service_proposal.provider.cnpj || ''
        end
        
        # Limpa linhas não usadas
        (@order_service_invoices.length...@template_size).each do |i|
          index_str = i < 9 ? "0#{i+1}" : (i+1).to_s
          %w[DATA DESCRICAO VALOR NOTA IR FORNECEDOR CNPJ].each do |field|
            replacements["#{index_str}#{field}"] = ''
          end
        end
      end

      # Escapa caracteres especiais XML para evitar corrupção do DOCX
      def escape_xml(value)
        value.to_s
             .gsub('&', '&amp;')
             .gsub('<', '&lt;')
             .gsub('>', '&gt;')
             .gsub('"', '&quot;')
             .gsub("'", '&apos;')
      end

      def generate_docx_without_rename(template_path, output_path, replacements)
        # Lê todo o conteúdo do template em memória
        entries_data = {}
        
        Zip::File.open(template_path.to_s) do |zip_file|
          zip_file.each do |entry|
            content = entry.get_input_stream.read
            
            # Substitui placeholders em arquivos XML (com escape de caracteres especiais)
            if entry.name =~ /\.xml$/ || entry.name =~ /\.rels$/
              content = content.force_encoding('UTF-8')
              
              # CORREÇÃO: O Word fragmenta texto em múltiplos <w:r> runs.
              # Ex: "NOSSONUMERO" pode virar <w:r><w:t>NOSSO</w:t></w:r><w:r><w:t>NUMERO</w:t></w:r>
              # Precisamos juntar os runs antes de substituir, e depois aplicar os replacements.
              content = merge_split_placeholders(content, replacements.keys)
              
              replacements.each do |key, value|
                content = content.gsub(key.to_s, escape_xml(value))
              end
            end
            
            entries_data[entry.name] = content
          end
        end
        
        # Escreve diretamente no arquivo de saída usando File.open
        # Isso evita o File.rename problemático
        File.open(output_path.to_s, 'wb') do |file|
          buffer = Zip::OutputStream.write_buffer do |zos|
            entries_data.each do |name, content|
              zos.put_next_entry(name)
              zos.write(content)
            end
          end
          buffer.rewind
          file.write(buffer.read)
        end
      end

      def cleanup_old_invoices
        # Remove faturas geradas há mais de 1 hora do diretório public/
        Dir.glob(Rails.root.join('public', 'fatura_gerada_*.docx')).each do |file|
          if File.mtime(file) < 1.hour.ago
            File.delete(file) rescue nil
          end
        end
      rescue => e
        # Ignora erros de limpeza para não impactar a geração
        Rails.logger.warn "Erro ao limpar faturas antigas: #{e.message}"
      end

      # Junta texto fragmentado pelo Word em múltiplos <w:r> runs.
      # O Word pode quebrar "NOSSONUMERO" em <w:r><w:t>NOSSO</w:t></w:r><w:r><w:t>NUMERO</w:t></w:r>.
      # Esta função detecta quando um placeholder está fragmentado e junta os runs em um só.
      #
      # OTIMIZAÇÃO: Processa apenas os placeholders globais (não-numéricos) que são
      # os únicos passíveis de fragmentação pelo Word. Placeholders numéricos (01DATA, 02VALOR, etc.)
      # ficam em células de tabela e nunca são fragmentados.
      def merge_split_placeholders(xml_content, placeholder_keys)
        # Filtra apenas placeholders que: (1) não existem inteiros no XML, (2) não são numéricos de tabela
        global_keys = placeholder_keys.select do |k|
          key_str = k.to_s
          key_str.length >= 4 && !xml_content.include?(key_str) && key_str !~ /\A\d{1,3}(DATA|DESCRICAO|VALOR|NOTA|IR|FORNECEDOR|CNPJ)\z/
        end

        return xml_content if global_keys.empty?

        # Para cada parágrafo (<w:p>...</w:p>), extrai texto concatenado dos runs.
        # Se algum placeholder global aparece no texto concatenado, mescla os runs.
        xml_content.gsub(%r{<w:p[ >].*?</w:p>}m) do |paragraph|
          # Extrai texto de todos os <w:t> nodes dentro do parágrafo
          texts = paragraph.scan(%r{<w:t[^>]*>(.*?)</w:t>}m).flatten
          full_text = texts.join

          # Verifica se algum placeholder global está no texto concatenado
          needs_merge = global_keys.any? { |k| full_text.include?(k.to_s) }

          if needs_merge
            # Mescla runs adjacentes: substitui </w:t></w:r><w:r>...<w:t...> por nada
            # entre as partes de texto, efetivamente juntando o conteúdo dos runs
            xml_noise = %r{</w:t>\s*</w:r>\s*<w:r>(?:\s*<w:rPr>.*?</w:rPr>)?\s*<w:t[^>]*>}m
            paragraph.gsub(xml_noise, '')
          else
            paragraph
          end
        end
      end

      # Busca a proposta aprovada SEM chamar ensure_total_values (read-only)
      # Evita efeito colateral de recalcular e gravar totais durante geração de fatura
      def find_approved_proposal_readonly(order_service)
        approved_statuses = [
          OrderServiceProposalStatus::APROVADA_ID,
          OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
          OrderServiceProposalStatus::AUTORIZADA_ID,
          OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
          OrderServiceProposalStatus::PAGA_ID
        ]

        result = order_service.order_service_proposals
          .where(is_complement: [false, nil])
          .where(order_service_proposal_status_id: approved_statuses)
          .order(updated_at: :desc)
          .first

        result || order_service.order_service_proposals
          .where(order_service_proposal_status_id: approved_statuses)
          .order(updated_at: :desc)
          .first
      end

      def getting_values_by_proposals
        total_parts = 0
        total_services = 0
        total_discount_ir = 0
        total_retencao_esfera = 0

        # Desconto do cliente (percentual)
        client_discount_pct = (@client.discount_percent || 0).to_d / 100

        # Verifica se cliente é municipal ou estadual (para retenção de esfera)
        is_municipal_or_estadual = @client.municipal? || @client.estadual?

        @order_services.each do |order_service|
          proposal = find_approved_proposal_readonly(order_service)
          next unless proposal

          invoices = proposal.order_service_invoices.sort_by { |item| item.order_service_invoice_type_id }

          # Filtrar por tipo de fatura quando invoice_split está definido
          if @invoice_split == 'parts'
            invoices = invoices.select { |inv| inv.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }
          elsif @invoice_split == 'services'
            invoices = invoices.select { |inv| inv.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }
          end

          @order_service_invoices.concat(invoices)

          sum_parts = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }.sum(&:value).to_d
          sum_services = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }.sum(&:value).to_d

          total_parts += sum_parts
          total_services += sum_services

          # IR para optante simples
          if proposal.provider.optante_simples
            total_discount_ir += (sum_parts * 0.012)
            total_discount_ir += (sum_services * 0.048)
          end

          # Retenção por esfera: municipal/estadual + fornecedor NÃO optante simples
          if is_municipal_or_estadual && !proposal.provider.optante_simples
            total_retencao_esfera += (sum_parts * 0.0545)   # 5,45% peças
            total_retencao_esfera += (sum_services * 0.0945) # 9,45% serviços
          end
        end

        # Calcula totais a partir dos valores das NFs (sem depender de totais da proposta)
        total_value_without_discount = (total_parts + total_services).to_d
        total_discount = (total_value_without_discount * client_discount_pct).round(2)
        total_value = (total_value_without_discount - total_discount).to_d

        return {
          valortotal: total_value,
          descontoir: total_discount_ir,
          valorbruto: total_value_without_discount,
          desconto: total_discount,
          valorcomdesconto: total_value,
          retencoes: total_discount_ir,
          retencao_esfera: total_retencao_esfera
        }
      end
    end
  end
end
