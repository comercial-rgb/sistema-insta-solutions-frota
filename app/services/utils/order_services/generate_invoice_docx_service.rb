require 'zip'
require 'fileutils'

# NÃO usa mais docx_replace devido a problemas de File.rename no Windows
# Manipula o DOCX diretamente como arquivo ZIP

module Utils
  module OrderServices
    class GenerateInvoiceDocxService
      def initialize(order_services, client, current_month)
        @order_services = order_services
        @client = client
        @current_month = current_month
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
        
        # Dados do cliente
        cost_centers_name = @order_services.map { |os| os.cost_center.name }.uniq.join(' / ')
        replacements['NOMECLIENTE'] = @client.social_name || ''
        replacements['CENTRODECUSTO'] = cost_centers_name
        replacements['CNPJCLIENTE'] = @client.cnpj || ''
        replacements['ENDERECOCLIENTE'] = @client.get_address || ''
        replacements['CIDADECLIENTE'] = @client.get_city || ''
        replacements['ESTADOCLIENTE'] = @client.get_state || ''
        replacements['TELEFONECLIENTE'] = @client.phone || ''
        replacements['EMAILCLIENTE'] = @client.email || ''
        
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

      def getting_values_by_proposals
        total_value = 0
        total_discount = 0
        total_value_without_discount = 0
        total_discount_ir = 0
        order_service_invoices = []

        @order_services.each do |order_service|
          order_service_proposal_approved = order_service.getting_order_service_proposal_approved
          if order_service_proposal_approved
            @order_service_invoices.concat(order_service_proposal_approved.order_service_invoices.sort_by{|item| item.order_service_invoice_type_id})
            order_service_invoices_grouped = order_service_proposal_approved.order_service_invoices.group_by(&:order_service_invoice_type_id)
            total_value += order_service_proposal_approved.total_value
            total_discount += order_service_proposal_approved.total_discount
            total_value_without_discount += order_service_proposal_approved.total_value_without_discount
          end
          sum_parts = order_service_invoices_grouped[OrderServiceInvoiceType::PECAS_ID].sum(&:value) if !order_service_invoices_grouped[OrderServiceInvoiceType::PECAS_ID].nil?
          sum_services = order_service_invoices_grouped[OrderServiceInvoiceType::SERVICOS_ID].sum(&:value) if !order_service_invoices_grouped[OrderServiceInvoiceType::SERVICOS_ID].nil?
          if order_service_proposal_approved && order_service_proposal_approved.provider.optante_simples
            total_discount_ir += (sum_parts * 0.012).to_f if !sum_parts.nil?
            total_discount_ir += (sum_services * 0.048).to_f if !sum_services.nil?
          end
        end
        return {
          valortotal: total_value,
          descontoir: total_discount_ir,
          valorbruto: total_value_without_discount,
          desconto: total_discount,
          valorcomdesconto: (total_value_without_discount - total_discount),
          retencoes: total_discount_ir
        }
      end
    end
  end
end
