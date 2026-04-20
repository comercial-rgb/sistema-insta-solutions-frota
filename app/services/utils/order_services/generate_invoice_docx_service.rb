require 'zip'
require 'fileutils'

# Gera DOCX robusto a partir dos dados da Fatura (sem template)
# Layout: Fatura Gestao de Frotas, InstaSolutions, Cliente/Contratante, Itens, Resumo, Retencoes

module Utils
  module OrderServices
    class GenerateInvoiceDocxService
      INSTA_RAZAO = 'InstaSolutions Produtos e Gestao Empresarial LTDA'
      INSTA_CNPJ = '47.611.398/0001-66'
      INSTA_END = 'Alameda Rio Negro 1030, Alphaville Industrial, Barueri - SP'
      INSTA_TEL = '(11) 3336-6941'

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
        @invoice_split = opts[:invoice_split]
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
        split_label = case @invoice_split
                      when 'pecas' then '_PECAS'
                      when 'servicos' then '_SERVICOS'
                      else ''
                      end
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}#{split_label}_#{timestamp}.docx"
        output_path = Rails.root.join('tmp', output_filename)

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100
        is_federal = @client&.respond_to?(:federal?) && @client.federal?
        sphere_name = @client&.respond_to?(:sphere_name) ? @client.sphere_name : 'Municipal'

        os_rows = []
        total_pecas = 0; total_servicos = 0; total_bruto = 0
        total_desconto = 0; total_com_desc = 0
        providers_detail = []

        grouped = @items.select { |i| i.order_service_id.present? }.group_by(&:order_service_id)

        grouped.each do |_os_id, items|
          os = items.first.order_service
          next unless os

          proposal = find_approved_proposal(os)
          next unless proposal

          invoices = proposal.order_service_invoices.to_a
          nf_pecas = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }
          nf_servicos = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }

          if @invoice_split == 'pecas'
            nf_servicos = []
          elsif @invoice_split == 'servicos'
            nf_pecas = []
          end

          pecas_val = nf_pecas.sum(&:value).to_f
          servicos_val = nf_servicos.sum(&:value).to_f
          next if pecas_val == 0 && servicos_val == 0

          bruto = proposal.total_value_without_discount.to_f
          desc_val = (bruto * client_discount_pct).to_f.round(2)
          com_desc = bruto - desc_val

          provider = proposal.provider
          is_simples = provider ? !provider.optante_simples : true

          total_pecas += pecas_val; total_servicos += servicos_val
          total_bruto += bruto; total_desconto += desc_val; total_com_desc += com_desc

          pct_pecas_ret = 0; pct_serv_ret = 0; ret_provider = 0
          unless is_simples
            if is_federal
              pct_pecas_ret = 5.85; pct_serv_ret = 9.45
              ret_provider = pecas_val * 0.0585 + servicos_val * 0.0945
            else
              pct_pecas_ret = 1.20; pct_serv_ret = 4.80
              ret_provider = pecas_val * 0.012 + servicos_val * 0.048
            end
          end

          providers_detail << {
            os_code: os.code, name: provider&.get_name || '-', cnpj: provider&.cnpj || '-',
            is_simples: is_simples, pecas: pecas_val, servicos: servicos_val,
            pct_pecas: pct_pecas_ret, pct_servicos: pct_serv_ret, retencao: ret_provider.round(2)
          }

          os_rows << {
            code: os.code, provider: provider&.get_name || '-', provider_cnpj: provider&.cnpj || '-',
            regime: is_simples ? 'Simples Nacional' : 'Nao Optante Simples', vehicle: os.vehicle&.board || '-',
            cost_center: os.cost_center&.name || '-',
            pecas: pecas_val, nf_pecas: nf_pecas.map(&:number).compact.join(', '),
            servicos: servicos_val, nf_servicos: nf_servicos.map(&:number).compact.join(', '),
            bruto: bruto, desconto: desc_val, com_desc: com_desc,
            pct_desc: bruto > 0 ? ((desc_val / bruto) * 100).round(2) : 0,
            ret: ret_provider.round(2), pct_pecas_ret: pct_pecas_ret, pct_serv_ret: pct_serv_ret,
            is_simples: is_simples
          }
        end

        total_ret = providers_detail.sum { |p| p[:retencao] }.round(2)
        valor_devido = total_com_desc

        pct_desc = total_bruto > 0 ? ((total_desconto / total_bruto) * 100).round(2) : 0

        body_xml = ''

        # === HEADER: InstaSolutions ===
        body_xml << wp_heading('Fatura Gestao de Frotas', 18, align: 'center', color: '251C59')
        body_xml << wp_empty
        body_xml << wp_heading('Dados Gerenciadora', 12, color: '251C59')

        insta_rows = [
          ['Razao Social:', INSTA_RAZAO, 'CNPJ:', INSTA_CNPJ],
          ['Endereco:', INSTA_END, 'Telefone:', INSTA_TEL]
        ]
        body_xml << wp_table(insta_rows, [1600, 5800, 1200, 2400], font_size: 18, shd_all: 'F5F5F5')
        body_xml << wp_empty

        split_txt = case @invoice_split
                    when 'pecas' then ' (Somente Pecas)'
                    when 'servicos' then ' (Somente Servicos)'
                    else ''
                    end
        body_xml << wp_para("N\u00B0 #{@fatura.numero}#{split_txt}", 14, align: 'center', bold: true, color: '005BED')
        body_xml << wp_para("Emissao: #{fmt_date(@fatura.data_emissao)}  |  Vencimento: #{fmt_date(@fatura.data_vencimento)}  |  Status: #{@fatura.status.upcase}", 10, align: 'center')
        body_xml << wp_hr

        # === CLIENTE / CONTRATANTE ===
        body_xml << wp_heading('Cliente / Contratante', 13, color: '251C59')

        client_name = @client&.social_name.presence || @client&.fantasy_name.presence || @client&.name || '-'
        client_address = @client&.respond_to?(:get_address) ? @client.get_address : '-'
        client_city = @client&.respond_to?(:get_city) ? @client.get_city : ''
        client_state = @client&.respond_to?(:get_state) ? @client.get_state : ''
        client_city_uf = [client_city, client_state].reject(&:blank?).join(' / ')
        client_phone = @client&.phone || '-'
        client_email = @client&.email || '-'

        client_rows = [
          ['Razao Social:', client_name, 'CNPJ:', @client&.cnpj || '-'],
          ['Endereco:', "#{client_address} - #{client_city_uf}", 'Esfera:', sphere_name],
          ['Desconto Contrato:', "#{fmt_pct(@client&.discount_percent)}%", 'Contatos:', "#{client_phone} / #{client_email}"]
        ]
        if @fatura.contract&.number
          client_rows << ['Contrato:', @fatura.contract.number, 'Centro de Custo:', @fatura.cost_center&.name || '-']
        end
        body_xml << wp_table(client_rows, [1800, 5000, 1600, 2600], font_size: 18, shd_all: 'F8F8FF')
        body_xml << wp_hr

        # === ITENS DA FATURA ===
        body_xml << wp_heading('Itens da Fatura', 13, color: '251C59')

        item_header = ['OS', 'Fornecedor', 'Veiculo', 'C.Custo', 'NF Pecas', 'Vl. Pecas', 'NF Servicos', 'Vl. Servicos', 'V.Bruto', 'Desc.', 'V.c/Desc.']
        item_rows = [item_header]

        os_rows.each do |r|
          item_rows << [
            "##{r[:code]}", r[:provider].to_s[0..24], r[:vehicle],
            r[:cost_center].to_s[0..14],
            r[:nf_pecas].presence || '-', money(r[:pecas]),
            r[:nf_servicos].presence || '-', money(r[:servicos]),
            money(r[:bruto]), "-#{money(r[:desconto])}", money(r[:com_desc])
          ]
          regime_txt = r[:is_simples] ? 'Optante Simples (Isento)' : "Nao Optante - Ret. Pecas #{fmt_pct(r[:pct_pecas_ret])}% / Servicos #{fmt_pct(r[:pct_serv_ret])}% = #{money(r[:ret])}"
          item_rows << :sub_row
          item_rows << { sub: true, text: "CNPJ: #{r[:provider_cnpj]}  |  #{regime_txt}" }
        end

        item_rows << [
          '', '', '', 'SUBTOTAIS:',
          '', money(total_pecas), '', money(total_servicos),
          money(total_bruto), "-#{money(total_desconto)}", money(total_com_desc)
        ]

        col_w = [700, 1800, 750, 1100, 900, 1000, 900, 1050, 950, 950, 900]
        body_xml << wp_items_table(item_rows, col_w)
        body_xml << wp_empty

        # === RESUMO FINANCEIRO ===
        body_xml << wp_heading('Resumo Financeiro', 13, color: '251C59')

        desc_pecas = (total_pecas * client_discount_pct).round(2)
        desc_servicos = (total_servicos * client_discount_pct).round(2)
        desc_bruto = total_desconto

        fin_rows = [
          ['', 'Pecas (NF)', 'Servicos (NF)', 'V. Bruto', 'Total'],
          ['Valor sem desconto', money(total_pecas), money(total_servicos), money(total_bruto), money(total_bruto)],
          ["(-) Desconto (#{fmt_pct(pct_desc)}%)", "-#{money(desc_pecas)}", "-#{money(desc_servicos)}", "-#{money(desc_bruto)}", "-#{money(total_desconto)}"],
          ['Valor c/ Desconto', money(total_pecas - desc_pecas), money(total_servicos - desc_servicos), money(total_com_desc), money(total_com_desc)]
        ]
        body_xml << wp_table(fin_rows, [2200, 1800, 1800, 1800, 2000], header_row: true, font_size: 19)
        body_xml << wp_empty

        # === RETENCOES FISCAIS (informativo) ===
        if total_ret > 0
          pct_p_str = is_federal ? '5,85%' : '1,20%'
          pct_s_str = is_federal ? '9,45%' : '4,80%'
          ret_pecas_total = providers_detail.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:pecas] * 0.0585 : p[:pecas] * 0.012 }
          ret_servicos_total = providers_detail.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:servicos] * 0.0945 : p[:servicos] * 0.048 }

          body_xml << wp_heading("Retencoes Fiscais - #{sphere_name}", 11, color: 'C57200')

          ret_summ = [
            ["Pecas Nao-Simples (#{pct_p_str})", "-#{money(ret_pecas_total)}"],
            ["Servicos Nao-Simples (#{pct_s_str})", "-#{money(ret_servicos_total)}"],
            ['Total Retencoes', "-#{money(total_ret)}"]
          ]
          body_xml << wp_table(ret_summ, [7500, 3500], font_size: 18)
          body_xml << wp_empty

          non_simples = providers_detail.reject { |p| p[:is_simples] }
          if non_simples.any?
            body_xml << wp_heading('Detalhamento de Retencao por Fornecedor', 11, color: '251C59')
            det_header = ['OS', 'Fornecedor', 'CNPJ', '% Pecas', 'Ret. Pecas', '% Servicos', 'Ret. Servicos', 'Total Ret.']
            det_rows = [det_header]
            non_simples.each do |p|
              ret_p = is_federal ? p[:pecas] * 0.0585 : p[:pecas] * 0.012
              ret_s = is_federal ? p[:servicos] * 0.0945 : p[:servicos] * 0.048
              det_rows << [
                "##{p[:os_code]}", p[:name].to_s[0..22], p[:cnpj],
                "#{fmt_pct(p[:pct_pecas])}%", "-#{money(ret_p)}",
                "#{fmt_pct(p[:pct_servicos])}%", "-#{money(ret_s)}",
                "-#{money(p[:retencao])}"
              ]
            end
            det_rows << ['', '', 'TOTAL:', '', "-#{money(ret_pecas_total)}", '', "-#{money(ret_servicos_total)}", "-#{money(total_ret)}"]
            body_xml << wp_table(det_rows, [700, 2200, 1600, 900, 1200, 1000, 1200, 1200], header_row: true, font_size: 17)
            body_xml << wp_empty
          end
        else
          body_xml << wp_para('Todos os fornecedores sao Simples Nacional - isento de retencao fiscal.', 10, color: '28A745')
          body_xml << wp_empty
        end

        # === VALOR DEVIDO (antes da retencao) ===
        body_xml << wp_shaded_bar("VALOR DEVIDO: #{money(valor_devido)}")
        body_xml << wp_empty

        if @fatura.observacoes.present?
          body_xml << wp_heading('Observacoes', 11, color: '666666')
          body_xml << wp_para(@fatura.observacoes, 10)
        end

        body_xml << wp_hr
        body_xml << wp_para("Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} - Frota Insta Solutions", 8, align: 'center', color: '999999')

        write_docx(output_path, body_xml)
        output_path.to_s
      end

      def generate_from_order_services
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_gerada_#{timestamp}_#{SecureRandom.hex(4)}.docx"
        output_path = Rails.root.join('tmp', output_filename)

        body_xml = wp_heading('Fatura Gestao de Frotas', 18, align: 'center', color: '251C59')
        body_xml << wp_para("#{INSTA_RAZAO}  |  CNPJ: #{INSTA_CNPJ}", 9, align: 'center')
        body_xml << wp_para("Cliente: #{@client&.social_name || @client&.name || '-'}  |  CNPJ: #{@client&.cnpj || '-'}", 10)
        body_xml << wp_hr

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100
        is_federal = @client&.respond_to?(:federal?) && @client.federal?

        table_header = ['OS', 'Fornecedor', 'Veiculo', 'Tipo', 'NF', 'Valor NF', 'Retencao']
        table_rows = [table_header]
        total_val = 0; total_ret = 0

        @order_services.each do |os|
          proposal = find_approved_proposal(os)
          next unless proposal

          invoices = proposal.order_service_invoices.sort_by(&:order_service_invoice_type_id)
          invoices.each do |inv|
            is_pecas = inv.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID
            desc = is_pecas ? 'Pecas' : 'Servicos'
            ret = 0
            if proposal.provider&.optante_simples
              ret = is_federal ? (is_pecas ? inv.value * 0.0585 : inv.value * 0.0945) : (is_pecas ? inv.value * 0.012 : inv.value * 0.048)
            end
            total_val += inv.value.to_f
            total_ret += ret

            table_rows << [
              "##{os.code}", proposal.provider&.get_name.to_s[0..19] || '-',
              os.vehicle&.board || '-', desc, inv.number.to_s,
              money(inv.value), money(ret)
            ]
          end
        end

        col_widths = [700, 1800, 900, 900, 800, 1200, 1200]
        body_xml << wp_table(table_rows, col_widths, header_row: true)
        body_xml << wp_empty

        total_desc = (total_val * client_discount_pct).round(2)
        body_xml << wp_para("Valor Total NFs: #{money(total_val)}", 11, bold: true)
        body_xml << wp_para("(-) Desconto: -#{money(total_desc)}", 11)
        body_xml << wp_para("(-) Retencoes (informativo): -#{money(total_ret.round(2))}", 11)
        body_xml << wp_shaded_bar("VALOR DEVIDO: #{money(total_val - total_desc)}")

        body_xml << wp_hr
        body_xml << wp_para("Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} - Frota Insta Solutions", 8, align: 'center', color: '999999')

        write_docx(output_path, body_xml)
        output_path.to_s
      end

      # ===== DOCX XML Generation (Valid OOXML) =====

      def write_docx(output_path, body_xml)
        File.open(output_path.to_s, 'wb') do |file|
          buffer = Zip::OutputStream.write_buffer do |zos|
            zos.put_next_entry('[Content_Types].xml')
            zos.write(xml_content_types)
            zos.put_next_entry('_rels/.rels')
            zos.write(xml_rels)
            zos.put_next_entry('word/_rels/document.xml.rels')
            zos.write(xml_document_rels)
            zos.put_next_entry('word/document.xml')
            zos.write(xml_document(body_xml))
            zos.put_next_entry('word/styles.xml')
            zos.write(xml_styles)
          end
          buffer.rewind
          file.write(buffer.read)
        end
      end

      def xml_content_types
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' \
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' \
        '<Default Extension="xml" ContentType="application/xml"/>' \
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' \
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' \
        '</Types>'
      end

      def xml_rels
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' \
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' \
        '</Relationships>'
      end

      def xml_document_rels
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' \
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' \
        '</Relationships>'
      end

      def xml_styles
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' \
        '<w:docDefaults>' \
        '<w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/>' \
        '<w:sz w:val="22"/><w:szCs w:val="22"/><w:lang w:val="pt-BR"/></w:rPr></w:rPrDefault>' \
        '<w:pPrDefault><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr></w:pPrDefault>' \
        '</w:docDefaults>' \
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">' \
        '<w:name w:val="Normal"/>' \
        '</w:style>' \
        '<w:style w:type="table" w:styleId="TableGrid">' \
        '<w:name w:val="Table Grid"/>' \
        '<w:basedOn w:val="Normal"/>' \
        '<w:tblPr><w:tblBorders>' \
        '<w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '<w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '<w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>' \
        '</w:tblBorders></w:tblPr>' \
        '</w:style>' \
        '</w:styles>'
      end

      def xml_document(body)
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' \
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' \
        '<w:body>' + body +
        '<w:sectPr>' \
        '<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>' \
        '<w:pgMar w:top="567" w:right="567" w:bottom="567" w:left="567" w:header="0" w:footer="0" w:gutter="0"/>' \
        '</w:sectPr>' \
        '</w:body></w:document>'
      end

      # --- Element builders ---

      def wp_heading(text, size, align: 'left', color: '000000')
        sz = size * 2
        '<w:p><w:pPr><w:jc w:val="' + align + '"/><w:spacing w:before="100" w:after="40"/></w:pPr>' \
        '<w:r><w:rPr><w:b/><w:sz w:val="' + sz.to_s + '"/><w:szCs w:val="' + sz.to_s + '"/>' \
        '<w:color w:val="' + color + '"/></w:rPr>' \
        '<w:t xml:space="preserve">' + esc(text) + '</w:t></w:r></w:p>'
      end

      def wp_para(text, size, align: 'left', bold: false, color: '000000')
        sz = size * 2
        b_tag = bold ? '<w:b/>' : ''
        '<w:p><w:pPr><w:jc w:val="' + align + '"/><w:spacing w:after="30"/></w:pPr>' \
        '<w:r><w:rPr>' + b_tag + '<w:sz w:val="' + sz.to_s + '"/><w:szCs w:val="' + sz.to_s + '"/>' \
        '<w:color w:val="' + color + '"/></w:rPr>' \
        '<w:t xml:space="preserve">' + esc(text) + '</w:t></w:r></w:p>'
      end

      def wp_empty
        '<w:p><w:pPr><w:spacing w:after="40"/></w:pPr></w:p>'
      end

      def wp_hr
        '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="4" w:space="1" w:color="CCCCCC"/></w:pBdr><w:spacing w:after="60"/></w:pPr></w:p>'
      end

      def wp_shaded_bar(text)
        '<w:p><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="251C59"/>' \
        '<w:spacing w:before="100" w:after="100"/><w:jc w:val="center"/></w:pPr>' \
        '<w:r><w:rPr><w:b/><w:sz w:val="32"/><w:szCs w:val="32"/>' \
        '<w:color w:val="FFFFFF"/></w:rPr>' \
        '<w:t xml:space="preserve">' + esc(text) + '</w:t></w:r></w:p>'
      end

      def wp_table(rows, col_widths, header_row: false, font_size: 18, shd_all: nil)
        total_w = col_widths.sum
        xml = '<w:tbl><w:tblPr>' \
              '<w:tblStyle w:val="TableGrid"/>' \
              '<w:tblW w:w="' + total_w.to_s + '" w:type="dxa"/>' \
              '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>' \
              '<w:tblBorders>' \
              '<w:top w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>' \
              '<w:left w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>' \
              '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>' \
              '<w:right w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>' \
              '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="DDDDDD"/>' \
              '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="DDDDDD"/>' \
              '</w:tblBorders></w:tblPr>'

        xml += '<w:tblGrid>'
        col_widths.each { |w| xml += '<w:gridCol w:w="' + w.to_s + '"/>' }
        xml += '</w:tblGrid>'

        rows.each_with_index do |row, ri|
          is_hdr = header_row && ri == 0
          is_last = ri == rows.length - 1

          xml += '<w:tr>'
          xml += '<w:trPr><w:tblHeader/></w:trPr>' if is_hdr

          row.each_with_index do |cell, ci|
            fill = if is_hdr
                     'D9E2F3'
                   elsif is_last && header_row
                     'F2F2F2'
                   elsif shd_all
                     shd_all
                   end

            shd = fill ? '<w:shd w:val="clear" w:color="auto" w:fill="' + fill + '"/>' : ''
            bold_tag = (is_hdr || (is_last && header_row)) ? '<w:b/>' : ''
            fsz = font_size.to_s
            w = col_widths[ci] || 1000

            xml += '<w:tc><w:tcPr><w:tcW w:w="' + w.to_s + '" w:type="dxa"/>' + shd + '</w:tcPr>'
            xml += '<w:p><w:pPr><w:spacing w:after="10" w:line="240" w:lineRule="auto"/></w:pPr>'
            xml += '<w:r><w:rPr>' + bold_tag + '<w:sz w:val="' + fsz + '"/><w:szCs w:val="' + fsz + '"/></w:rPr>'
            xml += '<w:t xml:space="preserve">' + esc(cell.to_s) + '</w:t></w:r></w:p></w:tc>'
          end

          xml += '</w:tr>'
        end

        xml += '</w:tbl>'
        xml
      end

      def wp_items_table(rows, col_widths)
        total_w = col_widths.sum
        ncols = col_widths.length

        xml = '<w:tbl><w:tblPr>' \
              '<w:tblStyle w:val="TableGrid"/>' \
              '<w:tblW w:w="' + total_w.to_s + '" w:type="dxa"/>' \
              '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>' \
              '<w:tblBorders>' \
              '<w:top w:val="single" w:sz="4" w:space="0" w:color="BBBBBB"/>' \
              '<w:left w:val="single" w:sz="4" w:space="0" w:color="BBBBBB"/>' \
              '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="BBBBBB"/>' \
              '<w:right w:val="single" w:sz="4" w:space="0" w:color="BBBBBB"/>' \
              '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="DDDDDD"/>' \
              '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="DDDDDD"/>' \
              '</w:tblBorders></w:tblPr>'

        xml += '<w:tblGrid>'
        col_widths.each { |w| xml += '<w:gridCol w:w="' + w.to_s + '"/>' }
        xml += '</w:tblGrid>'

        rows.each_with_index do |row, ri|
          next if row == :sub_row

          if row.is_a?(Hash) && row[:sub]
            xml += '<w:tr>'
            xml += '<w:tc><w:tcPr><w:tcW w:w="' + total_w.to_s + '" w:type="dxa"/>'
            xml += '<w:gridSpan w:val="' + ncols.to_s + '"/>'
            xml += '<w:shd w:val="clear" w:color="auto" w:fill="F5F5F5"/></w:tcPr>'
            xml += '<w:p><w:pPr><w:spacing w:after="5" w:line="240" w:lineRule="auto"/><w:ind w:left="200"/></w:pPr>'
            xml += '<w:r><w:rPr><w:i/><w:sz w:val="20"/><w:szCs w:val="20"/><w:color w:val="666666"/></w:rPr>'
            xml += '<w:t xml:space="preserve">' + esc(row[:text]) + '</w:t></w:r></w:p></w:tc>'
            xml += '</w:tr>'
            next
          end

          next unless row.is_a?(Array)

          is_hdr = ri == 0
          is_last = ri == rows.length - 1

          xml += '<w:tr>'
          xml += '<w:trPr><w:tblHeader/></w:trPr>' if is_hdr

          row.each_with_index do |cell, ci|
            fill = if is_hdr
                     'D9E2F3'
                   elsif is_last
                     'EBF0FA'
                   end

            shd = fill ? '<w:shd w:val="clear" w:color="auto" w:fill="' + fill + '"/>' : ''
            bold_tag = (is_hdr || is_last) ? '<w:b/>' : ''
            fsz = is_hdr ? '17' : '16'
            w = col_widths[ci] || 1000

            xml += '<w:tc><w:tcPr><w:tcW w:w="' + w.to_s + '" w:type="dxa"/>' + shd + '</w:tcPr>'
            xml += '<w:p><w:pPr><w:spacing w:after="10" w:line="240" w:lineRule="auto"/></w:pPr>'
            xml += '<w:r><w:rPr>' + bold_tag + '<w:sz w:val="' + fsz + '"/><w:szCs w:val="' + fsz + '"/></w:rPr>'
            xml += '<w:t xml:space="preserve">' + esc(cell.to_s) + '</w:t></w:r></w:p></w:tc>'
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
        val.to_s.encode(xml: :text)
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
