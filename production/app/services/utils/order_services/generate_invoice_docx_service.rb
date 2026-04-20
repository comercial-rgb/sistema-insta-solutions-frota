require 'zip'
require 'fileutils'

# Gera DOCX robusto a partir dos dados da Fatura (sem template)
# Layout idêntico ao PDF: Gerenciada, Fornecedores, Tabela de Itens, Resumo Financeiro

module Utils
  module OrderServices
    class GenerateInvoiceDocxService
      def initialize(order_services_or_fatura, client = nil, current_month = nil, **opts)
        if order_services_or_fatura.is_a?(Fatura)
          @fatura = order_services_or_fatura
          @client = @fatura.client
          @items = @fatura.fatura_itens.includes(
            order_service: [:vehicle, :cost_center, :sub_unit,
              { order_service_proposals: [:provider, :order_service_invoices] }]
          )
          @order_services = nil
        else
          @order_services = order_services_or_fatura
          @client = client
          @current_month = current_month
          @fatura = nil
          @items = nil
        end
        @tipo_valor = opts[:tipo_valor] || 'bruto'
      end

      def call
        if @fatura
          generate_from_fatura
        else
          generate_from_order_services
        end
      end

      private

      def generate_from_fatura
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}_#{timestamp}.docx"
        output_path = Rails.root.join('tmp', output_filename)

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100
        is_federal = @client&.respond_to?(:federal?) && @client.federal?
        sphere_name = @client&.respond_to?(:sphere_name) ? @client.sphere_name : 'Municipal'

        # Collect OS data
        os_rows = []
        total_pecas = 0; total_servicos = 0; total_bruto = 0
        total_desconto = 0; total_com_desc = 0
        providers_info = []

        grouped = @items.select { |i| i.order_service_id.present? }.group_by(&:order_service_id)

        grouped.each do |_os_id, items|
          os = items.first.order_service
          next unless os

          proposal = find_approved_proposal(os)
          next unless proposal

          invoices = proposal.order_service_invoices.to_a
          nf_pecas = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }
          nf_servicos = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }

          pecas_val = nf_pecas.sum(&:value).to_f
          servicos_val = nf_servicos.sum(&:value).to_f
          bruto = proposal.total_value_without_discount.to_f
          desc_val = (bruto * client_discount_pct).to_f.round(2)
          com_desc = bruto - desc_val

          provider = proposal.provider
          is_simples = provider ? !provider.optante_simples : true

          total_pecas += pecas_val; total_servicos += servicos_val
          total_bruto += bruto; total_desconto += desc_val; total_com_desc += com_desc

          providers_info << { is_simples: is_simples, nf_pecas_val: nf_pecas.sum(&:value).to_f, nf_servicos_val: nf_servicos.sum(&:value).to_f }

          os_rows << {
            code: os.code, provider: provider&.get_name || '-', provider_cnpj: provider&.cnpj || '-',
            regime: is_simples ? 'Simples' : 'Não-Simples', vehicle: os.vehicle&.board || '-',
            cost_center: os.cost_center&.name || '-',
            pecas: pecas_val, nf_pecas: nf_pecas.map(&:number).compact.join(', '),
            servicos: servicos_val, nf_servicos: nf_servicos.map(&:number).compact.join(', '),
            bruto: bruto, desconto: desc_val, com_desc: com_desc,
            pct_desc: bruto > 0 ? ((desc_val / bruto) * 100).round(2) : 0
          }
        end

        # Retenções
        total_ret = 0
        providers_info.each do |p|
          next if p[:is_simples]
          if is_federal
            total_ret += p[:nf_pecas_val] * 0.0585 + p[:nf_servicos_val] * 0.0945
          else
            total_ret += p[:nf_pecas_val] * 0.012 + p[:nf_servicos_val] * 0.048
          end
        end
        total_ret = total_ret.round(2)
        valor_devido = total_com_desc - total_ret

        pct_desc = total_bruto > 0 ? ((total_desconto / total_bruto) * 100).round(2) : 0

        # Build XML
        body_xml = ''

        # Header
        body_xml += heading("FATURA DE SERVIÇOS", 24, align: 'center', color: '251C59')
        body_xml += paragraph("Nº #{@fatura.numero}", 14, align: 'center', bold: true, color: '005BED')
        body_xml += paragraph("Emissão: #{fmt_date(@fatura.data_emissao)}    |    Vencimento: #{fmt_date(@fatura.data_vencimento)}    |    Status: #{@fatura.status.upcase}", 9, align: 'center')
        body_xml += horizontal_line

        # Client
        body_xml += heading("GERENCIADA / CLIENTE", 11, color: '251C59')
        client_name = @client&.fantasy_name.presence || @client&.social_name.presence || @client&.name || '-'
        body_xml += paragraph("Razão Social: #{client_name}        CNPJ: #{@client&.cnpj || '-'}", 9)
        body_xml += paragraph("Esfera: #{sphere_name}        Desconto Contrato: #{fmt_pct(@client&.discount_percent)}%", 9)
        if @fatura.contract&.number || @fatura.cost_center&.name
          parts = []
          parts << "Contrato: #{@fatura.contract.number}" if @fatura.contract&.number
          parts << "Centro de Custo: #{@fatura.cost_center.name}" if @fatura.cost_center&.name
          body_xml += paragraph(parts.join('    |    '), 9)
        end
        body_xml += horizontal_line

        # Items table
        body_xml += heading("ITENS DA FATURA", 11, color: '251C59')

        table_header = ['OS', 'Fornecedor', 'Veículo', 'C.Custo', 'Peças (NF)', 'Serviços (NF)', 'V.Bruto', 'Desc.', 'V.c/Desc.']
        table_rows = [table_header]

        os_rows.each do |r|
          pecas_str = money(r[:pecas])
          pecas_str += " (NF #{r[:nf_pecas]})" if r[:nf_pecas].present?
          servicos_str = money(r[:servicos])
          servicos_str += " (NF #{r[:nf_servicos]})" if r[:nf_servicos].present?

          table_rows << [
            "##{r[:code]}", "#{r[:provider].truncate(20)} (#{r[:regime]})", r[:vehicle],
            r[:cost_center].truncate(15), pecas_str, servicos_str, money(r[:bruto]),
            "-#{money(r[:desconto])} (#{fmt_pct(r[:pct_desc])}%)", money(r[:com_desc])
          ]
        end

        table_rows << ['', '', '', 'SUBTOTAIS:', money(total_pecas), money(total_servicos),
                        money(total_bruto), "-#{money(total_desconto)}", money(total_com_desc)]

        col_widths = [600, 1400, 700, 900, 1000, 1000, 800, 900, 900]
        body_xml += build_table(table_rows, col_widths, header: true)
        body_xml += empty_paragraph

        # Financial Summary
        body_xml += heading("RESUMO FINANCEIRO", 11, color: '251C59')
        desc_pecas = total_pecas * (@client&.discount_percent || 0).to_d / 100
        desc_servicos = total_servicos * (@client&.discount_percent || 0).to_d / 100

        fin_rows = [
          ['', 'Peças', 'Serviços', 'Total'],
          ['Valor sem desconto', money(total_pecas), money(total_servicos), money(total_bruto)],
          ["(-) Desconto (#{fmt_pct(pct_desc)}%)", "-#{money(desc_pecas)}", "-#{money(desc_servicos)}", "-#{money(total_desconto)}"],
          ['Valor c/ Desconto', money(total_pecas - desc_pecas), money(total_servicos - desc_servicos), money(total_com_desc)]
        ]
        body_xml += build_table(fin_rows, [3000, 2000, 2000, 2000], header: true)
        body_xml += empty_paragraph

        # Retentions
        if total_ret > 0
          pct_pecas_str = is_federal ? '5,85%' : '1,20%'
          pct_serv_str = is_federal ? '9,45%' : '4,80%'
          ret_pecas = providers_info.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:nf_pecas_val] * 0.0585 : p[:nf_pecas_val] * 0.012 }
          ret_servicos = providers_info.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:nf_servicos_val] * 0.0945 : p[:nf_servicos_val] * 0.048 }

          body_xml += heading("RETENÇÕES FISCAIS (#{sphere_name})", 10, color: 'C57200')
          ret_rows = [
            ["Peças Não-Simples (#{pct_pecas_str})", "-#{money(ret_pecas)}"],
            ["Serviços Não-Simples (#{pct_serv_str})", "-#{money(ret_servicos)}"],
            ['Total Retenções', "-#{money(total_ret)}"]
          ]
          body_xml += build_table(ret_rows, [6000, 3000])
          body_xml += empty_paragraph
        else
          body_xml += paragraph("Todos os fornecedores são Simples Nacional — isento de retenção fiscal.", 9, color: '28A745')
        end

        # Valor Devido
        body_xml += shaded_bar("VALOR DEVIDO: #{money(valor_devido)}")
        body_xml += empty_paragraph

        # Observations
        if @fatura.observacoes.present?
          body_xml += heading("OBSERVAÇÕES", 10, color: '666666')
          body_xml += paragraph(@fatura.observacoes, 9)
        end

        # Footer
        body_xml += horizontal_line
        body_xml += paragraph("Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} — Frota Insta Solutions", 7, align: 'center', color: '999999')

        write_docx(output_path, body_xml)
        output_path.to_s
      end

      # Fallback: old interface for backward compatibility
      def generate_from_order_services
        # Create a minimal fatura-like generation for legacy callers
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_gerada_#{timestamp}_#{SecureRandom.hex(4)}.docx"
        output_path = Rails.root.join('tmp', output_filename)

        body_xml = heading("FATURA DE SERVIÇOS", 24, align: 'center', color: '251C59')
        body_xml += paragraph("Cliente: #{@client&.social_name || @client&.name || '-'}", 11)
        body_xml += paragraph("CNPJ: #{@client&.cnpj || '-'}", 9)
        body_xml += horizontal_line

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100
        is_federal = @client&.respond_to?(:federal?) && @client.federal?

        table_header = ['OS', 'Fornecedor', 'Veículo', 'Tipo', 'NF', 'Valor NF', 'Retenção']
        table_rows = [table_header]
        total_val = 0; total_ret = 0

        @order_services.each do |os|
          proposal = find_approved_proposal(os)
          next unless proposal

          invoices = proposal.order_service_invoices.sort_by(&:order_service_invoice_type_id)
          invoices.each do |inv|
            is_pecas = inv.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID
            desc = is_pecas ? 'Peças' : 'Serviços'
            ret = 0
            if proposal.provider&.optante_simples
              ret = is_federal ? (is_pecas ? inv.value * 0.0585 : inv.value * 0.0945) : (is_pecas ? inv.value * 0.012 : inv.value * 0.048)
            end
            total_val += inv.value.to_f
            total_ret += ret

            table_rows << [
              "##{os.code}", proposal.provider&.get_name&.truncate(20) || '-',
              os.vehicle&.board || '-', desc, inv.number.to_s,
              money(inv.value), money(ret)
            ]
          end
        end

        col_widths = [700, 1800, 900, 900, 800, 1200, 1200]
        body_xml += build_table(table_rows, col_widths, header: true)
        body_xml += empty_paragraph

        total_desc = (total_val * client_discount_pct).round(2)
        body_xml += paragraph("Valor Total NFs: #{money(total_val)}", 10, bold: true)
        body_xml += paragraph("(-) Desconto: -#{money(total_desc)}", 10)
        body_xml += paragraph("(-) Retenções: -#{money(total_ret.round(2))}", 10)
        body_xml += shaded_bar("VALOR DEVIDO: #{money(total_val - total_desc - total_ret.round(2))}")

        body_xml += horizontal_line
        body_xml += paragraph("Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} — Frota Insta Solutions", 7, align: 'center', color: '999999')

        write_docx(output_path, body_xml)
        output_path.to_s
      end

      # ===== DOCX XML Helpers =====

      def write_docx(output_path, body_xml)
        File.open(output_path.to_s, 'wb') do |file|
          buffer = Zip::OutputStream.write_buffer do |zos|
            zos.put_next_entry('[Content_Types].xml')
            zos.write(content_types_xml)
            zos.put_next_entry('_rels/.rels')
            zos.write(rels_xml)
            zos.put_next_entry('word/_rels/document.xml.rels')
            zos.write(document_rels_xml)
            zos.put_next_entry('word/document.xml')
            zos.write(document_xml(body_xml))
            zos.put_next_entry('word/styles.xml')
            zos.write(styles_xml)
          end
          buffer.rewind
          file.write(buffer.read)
        end
      end

      def document_xml(body)
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
                      xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
                      xmlns:o="urn:schemas-microsoft-com:office:office"
                      xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                      xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
                      xmlns:v="urn:schemas-microsoft-com:vml"
                      xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
                      xmlns:w10="urn:schemas-microsoft-com:office:word"
                      xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
                      xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
                      xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
                      xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
                      xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
                      xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
                      mc:Ignorable="w14 wp14">
            <w:body>
              #{body}
              <w:sectPr>
                <w:pgSz w:w="11906" w:h="16838"/>
                <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="708" w:footer="708" w:gutter="0"/>
              </w:sectPr>
            </w:body>
          </w:document>
        XML
      end

      def content_types_xml
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
          </Types>
        XML
      end

      def rels_xml
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
          </Relationships>
        XML
      end

      def document_rels_xml
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
          </Relationships>
        XML
      end

      def styles_xml
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
              <w:name w:val="Normal"/>
              <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="20"/></w:rPr>
            </w:style>
          </w:styles>
        XML
      end

      def heading(text, size, align: 'left', color: '000000')
        <<~XML
          <w:p>
            <w:pPr><w:jc w:val="#{align}"/><w:spacing w:before="120" w:after="60"/></w:pPr>
            <w:r><w:rPr><w:b/><w:sz w:val="#{size * 2}"/><w:szCs w:val="#{size * 2}"/><w:color w:val="#{color}"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr><w:t>#{esc(text)}</w:t></w:r>
          </w:p>
        XML
      end

      def paragraph(text, size, align: 'left', bold: false, color: '000000')
        b_tag = bold ? '<w:b/>' : ''
        <<~XML
          <w:p>
            <w:pPr><w:jc w:val="#{align}"/><w:spacing w:after="40"/></w:pPr>
            <w:r><w:rPr>#{b_tag}<w:sz w:val="#{size * 2}"/><w:szCs w:val="#{size * 2}"/><w:color w:val="#{color}"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr><w:t xml:space="preserve">#{esc(text)}</w:t></w:r>
          </w:p>
        XML
      end

      def empty_paragraph
        '<w:p><w:pPr><w:spacing w:after="60"/></w:pPr></w:p>'
      end

      def horizontal_line
        <<~XML
          <w:p>
            <w:pPr><w:pBdr><w:bottom w:val="single" w:sz="4" w:space="1" w:color="CCCCCC"/></w:pBdr><w:spacing w:after="80"/></w:pPr>
          </w:p>
        XML
      end

      def shaded_bar(text)
        <<~XML
          <w:p>
            <w:pPr>
              <w:shd w:val="clear" w:color="auto" w:fill="251C59"/>
              <w:spacing w:before="120" w:after="120"/>
              <w:jc w:val="center"/>
            </w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/><w:color w:val="FFFFFF"/><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/></w:rPr>
              <w:t>#{esc(text)}</w:t>
            </w:r>
          </w:p>
        XML
      end

      def build_table(rows, col_widths, header: false)
        grid_xml = col_widths.map { |w| "<w:gridCol w:w=\"#{w}\"/>" }.join

        xml = "<w:tbl><w:tblPr><w:tblStyle w:val=\"TableGrid\"/><w:tblW w:w=\"0\" w:type=\"auto\"/>"
        xml += "<w:tblBorders>"
        %w[top left bottom right insideH insideV].each do |border|
          xml += "<w:#{border} w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"DDDDDD\"/>"
        end
        xml += "</w:tblBorders></w:tblPr>"
        xml += "<w:tblGrid>#{grid_xml}</w:tblGrid>"

        rows.each_with_index do |row, ri|
          is_header = header && ri == 0
          is_last = ri == rows.length - 1

          xml += '<w:tr>'
          if is_header
            xml += '<w:trPr><w:tblHeader/></w:trPr>'
          end

          row.each_with_index do |cell, ci|
            shd = ''
            if is_header
              shd = '<w:shd w:val="clear" w:color="auto" w:fill="E8E8E8"/>'
            elsif is_last && header
              shd = '<w:shd w:val="clear" w:color="auto" w:fill="F5F5F5"/>'
            end

            align = ci >= (row.length - 5) && row.length > 5 ? 'right' : 'left'
            bold = is_header || (is_last && header) ? '<w:b/>' : ''
            font_size = is_header ? 14 : 13

            xml += "<w:tc><w:tcPr><w:tcW w:w=\"#{col_widths[ci] || 1000}\" w:type=\"dxa\"/>#{shd}</w:tcPr>"
            xml += "<w:p><w:pPr><w:jc w:val=\"#{align}\"/><w:spacing w:after=\"20\"/></w:pPr>"
            xml += "<w:r><w:rPr>#{bold}<w:sz w:val=\"#{font_size}\"/><w:szCs w:val=\"#{font_size}\"/><w:rFonts w:ascii=\"Calibri\" w:hAnsi=\"Calibri\"/></w:rPr>"
            xml += "<w:t xml:space=\"preserve\">#{esc(cell.to_s)}</w:t></w:r></w:p></w:tc>"
          end

          xml += '</w:tr>'
        end

        xml += '</w:tbl>'
        xml
      end

      def find_approved_proposal(order_service)
        approved_statuses = [
          OrderServiceProposalStatus::APROVADA_ID,
          OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
          OrderServiceProposalStatus::AUTORIZADA_ID,
          OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
          OrderServiceProposalStatus::PAGA_ID
        ].compact

        order_service.order_service_proposals
          .select { |p| approved_statuses.include?(p.order_service_proposal_status_id) && !p.is_complement }
          .sort_by(&:updated_at).last ||
        order_service.order_service_proposals
          .select { |p| approved_statuses.include?(p.order_service_proposal_status_id) }
          .sort_by(&:updated_at).last
      end

      def esc(val)
        val.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;').gsub("'", '&apos;')
      end

      def money(val)
        "R$ #{format('%.2f', val.to_f).gsub('.', ',').gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')}"
      end

      def fmt_date(date)
        date&.strftime('%d/%m/%Y') || '-'
      end

      def fmt_pct(val)
        format('%.2f', val.to_f).gsub('.', ',')
      end
    end
  end
end
