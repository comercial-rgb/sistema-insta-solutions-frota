require 'prawn'
require 'prawn/table'

module Utils
  module OrderServices
    class GenerateInvoicePdfService
      BLUE_DARK  = '251C59'
      BLUE_LIGHT = '005BED'
      GREEN      = '28a745'
      RED        = 'dc3545'
      ORANGE     = 'c57200'
      GRAY_BG    = 'F5F5F5'
      HEADER_BG  = 'D9E2F3'

      INSTA_RAZAO = 'InstaSolutions Produtos e Gestão Empresarial LTDA'
      INSTA_CNPJ = '47.611.398/0001-66'
      INSTA_END = 'Alameda Rio Negro 1030, Alphaville Industrial, Barueri - SP'
      INSTA_TEL = '(11) 3336-6941'
      LOGO_PATH = Rails.root.join('app', 'assets', 'images', "InstaSolutions-S\u00edmbolo-AzulCorp.png").to_s

      def initialize(fatura, invoice_split: nil, tipo_valor: 'bruto')
        @fatura = fatura
        @client = fatura.client
        @invoice_split = invoice_split
        @tipo_valor = tipo_valor
        @items = fatura.fatura_itens.includes(
          order_service: [:vehicle, :cost_center, :sub_unit, :commitment, :commitment_parts, :commitment_services,
            { order_service_proposals: [:provider, :order_service_invoices] }]
        )
      end

      def call
        split_label = case @invoice_split
                      when 'pecas' then '_PECAS'
                      when 'servicos' then '_SERVICOS'
                      else ''
                      end
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}#{split_label}_#{timestamp}.pdf"
        output_path = Rails.root.join('tmp', output_filename)

        Prawn::Document.generate(output_path.to_s, page_size: 'A4', page_layout: :landscape, margin: [25, 25, 25, 25]) do |pdf|
          @pdf = pdf
          pdf.font 'Helvetica'

          build_header
          build_client_block
          build_contract_block
          build_items_table
          build_financial_summary
          build_retention_detail
          build_provider_retention_table
          build_valor_devido_bar
          build_observations
          build_footer
        end

        output_path.to_s
      end

      private

      def build_header        # Logo top-left
        if File.exist?(LOGO_PATH)
          logo_top = @pdf.cursor
          @pdf.image LOGO_PATH, width: 35, at: [0, logo_top]
        end
        @pdf.font_size 18
        @pdf.text "Fatura Gestão de Frotas", style: :bold, align: :center, color: BLUE_DARK
        @pdf.move_down 6

        @pdf.font_size 11
        @pdf.text "Dados Gerenciadora", style: :bold, color: BLUE_DARK
        @pdf.move_down 3

        # InstaSolutions info table
        insta_data = [
          [{ content: 'Razão Social:', font_style: :bold }, INSTA_RAZAO, { content: 'CNPJ:', font_style: :bold }, INSTA_CNPJ],
          [{ content: 'Endereço:', font_style: :bold }, INSTA_END, { content: 'Telefone:', font_style: :bold }, INSTA_TEL]
        ]
        @pdf.table(insta_data, width: @pdf.bounds.width,
                   cell_style: { size: 8, padding: [2, 4], borders: [:bottom], border_color: 'EEEEEE', background_color: GRAY_BG })
        @pdf.move_down 6

        split_txt = case @invoice_split
                    when 'pecas' then ' (Somente Pecas)'
                    when 'servicos' then ' (Somente Servicos)'
                    else ''
                    end
        @pdf.font_size 13
        @pdf.text "N\u00B0 #{@fatura.numero}#{split_txt}", style: :bold, align: :center, color: BLUE_LIGHT
        @pdf.move_down 4

        @pdf.font_size 9
        date_data = [
          [
            { content: "Emissão: #{fmt_date(@fatura.data_emissao)}", align: :left },
            { content: "Vencimento: #{fmt_date(@fatura.data_vencimento)}", align: :center },
            { content: "Status: #{@fatura.status.upcase}", align: :right }
          ]
        ]
        @pdf.table(date_data, width: @pdf.bounds.width, cell_style: { borders: [], padding: [2, 4], size: 9 })
        @pdf.move_down 4
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 6
      end

      def build_client_block
        # Derive contract from OS commitments if not directly linked
        @derived_contract = @fatura.contract
        unless @derived_contract
          @derived_contract = @items.map { |i| i.order_service }.compact.flat_map { |os|
            [os.commitment, os.commitment_parts, os.commitment_services].compact
          }.map(&:contract).compact.first
        end

        @pdf.font_size 11
        @pdf.text "Cliente / Contratante", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        client_name = @client&.social_name.presence || @client&.fantasy_name.presence || @client&.name || '-'
        cnpj = @client&.cnpj || '-'
        address = @client&.respond_to?(:get_address) ? @client.get_address : '-'
        city = @client&.respond_to?(:get_city) ? @client.get_city : ''
        state = @client&.respond_to?(:get_state) ? @client.get_state : ''
        city_uf = [city, state].reject(&:blank?).join(' / ')
        phone = @client&.phone || '-'
        email = @client&.email || '-'
        sphere = @client&.respond_to?(:sphere_name) ? @client.sphere_name : '-'

        client_data = [
          [{ content: 'Razão Social:', font_style: :bold }, client_name, { content: 'CNPJ:', font_style: :bold }, cnpj],
          [{ content: 'Endereço:', font_style: :bold }, "#{address} - #{city_uf}", { content: 'Esfera:', font_style: :bold }, sphere],
          [{ content: 'Desconto Contrato:', font_style: :bold }, "#{fmt_pct(@client&.discount_percent)}%", { content: 'Telefone:', font_style: :bold }, phone],
          [{ content: 'Centro de Custo:', font_style: :bold }, @fatura.cost_center&.name || '-', { content: 'E-mail:', font_style: :bold }, email]
        ]

        @pdf.table(client_data, width: @pdf.bounds.width,
                   cell_style: { size: 8, padding: [2, 4], borders: [:bottom], border_color: 'EEEEEE', background_color: 'F8F8FF' })
        @pdf.move_down 4
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 6
      end

      def build_contract_block
        @pdf.font_size 11
        @pdf.text "Contrato / Empenhos", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        unless @derived_contract
          @pdf.text "Nenhum contrato vinculado a esta fatura.", size: 9, color: '999999'
          @pdf.move_down 4
          @pdf.stroke_color 'CCCCCC'
          @pdf.stroke_horizontal_rule
          @pdf.move_down 6
          return
        end

        contract = @derived_contract
        saldo_total = contract.respond_to?(:get_total_value) ? contract.get_total_value.to_f : contract.total_value.to_f
        saldo_usado = contract.respond_to?(:get_used_value) ? contract.get_used_value.to_f : 0
        saldo_disponivel = contract.respond_to?(:get_disponible_value) ? contract.get_disponible_value.to_f : (saldo_total - saldo_usado)

        contrato_data = [
          [{ content: "Contrato N\u00ba:", font_style: :bold }, contract.number || '-',
           { content: 'Valor Total:', font_style: :bold }, money(saldo_total)],
          [{ content: 'Saldo Consumido:', font_style: :bold }, money(saldo_usado),
           { content: "Saldo Dispon\u00edvel:", font_style: :bold }, money(saldo_disponivel)]
        ]
        @pdf.table(contrato_data, width: @pdf.bounds.width,
                   cell_style: { size: 8, padding: [2, 4], borders: [:bottom], border_color: 'EEEEEE', background_color: 'F0F7FF' })
        @pdf.move_down 4

        empenhos = @items.map { |i| i.order_service }.compact.flat_map { |os|
          [os.commitment, os.commitment_parts, os.commitment_services].compact
        }.uniq(&:id)

        if empenhos.any?
          emp_header = ["Empenho N\u00ba", 'Saldo Inicial', 'Consumido', 'Restante']
          emp_rows = [emp_header.map { |h| { content: h, font_style: :bold } }]
          empenhos.each do |emp|
            saldo_ini = Commitment.respond_to?(:sum_budget_value) ? Commitment.sum_budget_value(emp).to_f : emp.commitment_value.to_f
            consumido = Commitment.respond_to?(:get_total_already_consumed_value) ? Commitment.get_total_already_consumed_value(emp).to_f : 0
            restante = emp.respond_to?(:get_available_balance) ? emp.get_available_balance.to_f : (saldo_ini - consumido)
            emp_rows << [emp.commitment_number || '-', money(saldo_ini), money(consumido), money(restante)]
          end
          @pdf.table(emp_rows, header: true, width: @pdf.bounds.width * 0.60,
                     cell_style: { size: 7.5, padding: [2, 4], borders: [:bottom], border_color: 'DDDDDD' }) do |t|
            t.row(0).background_color = HEADER_BG
            t.columns(1..3).align = :right
          end
        end

        @pdf.move_down 4
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 6
        @pdf.font_size 11
        @pdf.text "Itens da Fatura", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        header = ['OS', 'Fornecedor', 'Veículo', 'C.Custo', 'NF Peças', 'Vl. Peças', 'NF Serviços', 'Vl. Serviços', 'V.Bruto', 'Desc.', 'V.c/Desc.']
        rows = [header.map { |h| { content: h, font_style: :bold } }]

        @total_pecas = 0; @total_servicos = 0; @total_bruto = 0
        @total_desconto = 0; @total_com_desc = 0
        @total_pecas_display = 0; @total_servicos_display = 0
        @providers_detail = []

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100
        is_federal = @client&.respond_to?(:federal?) && @client.federal?

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

          pecas_nums = nf_pecas.map(&:number).compact.join(', ')
          servicos_nums = nf_servicos.map(&:number).compact.join(', ')

          provider = proposal.provider
          is_simples = provider ? !provider.optante_simples : true

          nf_total_os = pecas_val + servicos_val
          if @tipo_valor == 'bruto' && nf_total_os > 0
            pecas_display = (bruto * (pecas_val / nf_total_os)).round(2)
            servicos_display = (bruto - pecas_display).round(2)
          else
            pecas_display = pecas_val
            servicos_display = servicos_val
          end

          @total_pecas += pecas_val; @total_servicos += servicos_val
          @total_bruto += bruto; @total_desconto += desc_val; @total_com_desc += com_desc
          @total_pecas_display += pecas_display; @total_servicos_display += servicos_display

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

          @providers_detail << {
            os_code: os.code, name: provider&.get_name || '-', cnpj: provider&.cnpj || '-',
            is_simples: is_simples, pecas: pecas_val, servicos: servicos_val,
            pct_pecas: pct_pecas_ret, pct_servicos: pct_serv_ret, retencao: ret_provider.round(2)
          }

          pct = bruto > 0 ? ((desc_val / bruto) * 100).round(2) : 0

          # Main data row
          provider_name = provider&.get_name || '-'
          rows << [
            "##{os.code}",
            provider_name.truncate(22),
            os.vehicle&.board || '-',
            (os.cost_center&.name || '-').truncate(14),
            pecas_nums.presence || '-',
            money(pecas_display),
            servicos_nums.presence || '-',
            money(servicos_display),
            money(bruto),
            "-#{money(desc_val)}",
            money(com_desc)
          ]

          # Sub-row: CNPJ + regime + retention info
          regime_txt = is_simples ? 'Optante Simples (Isento)' : "Não Optante - Ret. Peças #{fmt_pct(pct_pecas_ret)}% / Serviços #{fmt_pct(pct_serv_ret)}% = #{money(ret_provider)}"
          rows << [{ content: "#{provider_name}  |  CNPJ: #{provider&.cnpj || '-'}  |  #{regime_txt}", colspan: 11, text_color: '888888', size: 7 }]
        end

        rows << [
          { content: 'SUBTOTAIS:', colspan: 4, font_style: :bold, align: :right },
          '', { content: money(@total_pecas_display), font_style: :bold, align: :right },
          '', { content: money(@total_servicos_display), font_style: :bold, align: :right },
          { content: money(@total_bruto), font_style: :bold, align: :right },
          { content: "-#{money(@total_desconto)}", font_style: :bold, align: :right, text_color: RED },
          { content: money(@total_com_desc), font_style: :bold, align: :right, text_color: GREEN }
        ]

        if rows.length > 2
          col_widths = [40, 100, 50, 60, 60, 65, 60, 70, 60, 60, 60]
          total_w = col_widths.sum
          scale = @pdf.bounds.width / total_w.to_f
          col_widths = col_widths.map { |w| (w * scale).floor }
          col_widths[-1] += (@pdf.bounds.width - col_widths.sum).to_i

          @pdf.table(rows, header: true, width: @pdf.bounds.width,
                     column_widths: col_widths,
                     cell_style: { size: 7, padding: [3, 3], borders: [:bottom], border_color: 'DDDDDD' }) do |t|
            t.row(0).background_color = HEADER_BG
            t.row(0).size = 7.5
            t.row(-1).background_color = GRAY_BG
            t.columns(5).align = :right
            t.columns(7).align = :right
            t.columns(8..10).align = :right
          end
        else
          @pdf.text "Nenhum item encontrado.", style: :italic, size: 8
        end

        @pdf.move_down 8
      end

      def build_financial_summary
        @pdf.font_size 11
        @pdf.text "Resumo Financeiro", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        pct_desc = @total_bruto > 0 ? ((@total_desconto / @total_bruto) * 100).round(2) : 0

        nf_total = @total_pecas + @total_servicos
        if nf_total > 0
          pecas_sem_desc = (@total_bruto * (@total_pecas / nf_total)).round(2)
          servicos_sem_desc = (@total_bruto - pecas_sem_desc).round(2)
        else
          pecas_sem_desc = 0; servicos_sem_desc = 0
        end
        desc_pecas = (pecas_sem_desc - @total_pecas).round(2)
        desc_servicos = (servicos_sem_desc - @total_servicos).round(2)

        @total_retencoes_calc = @providers_detail.sum { |p| p[:retencao] }.round(2)

        header = ['', 'Total s/ Desconto', 'Desconto', '% Desc.', 'Total c/ Desconto']
        data = [
          header.map { |h| { content: h, font_style: :bold } },
          ["Totais de Pe\u00E7as", { content: money(pecas_sem_desc), align: :right },
           { content: "-#{money(desc_pecas)}", align: :right, text_color: RED },
           { content: "#{fmt_pct(pct_desc)}%", align: :center },
           { content: money(@total_pecas), align: :right }],
          ["Totais de Servi\u00E7os", { content: money(servicos_sem_desc), align: :right },
           { content: "-#{money(desc_servicos)}", align: :right, text_color: RED },
           { content: "#{fmt_pct(pct_desc)}%", align: :center },
           { content: money(@total_servicos), align: :right }],
          [{ content: 'Totais do Pedido', font_style: :bold },
           { content: money(@total_bruto), align: :right, font_style: :bold },
           { content: "-#{money(@total_desconto)}", align: :right, font_style: :bold, text_color: RED },
           { content: "#{fmt_pct(pct_desc)}%", align: :center, font_style: :bold },
           { content: money(@total_com_desc), align: :right, font_style: :bold }]
        ]

        @pdf.table(data, width: @pdf.bounds.width * 0.75, position: :right,
                   cell_style: { size: 8, padding: [3, 5], borders: [:bottom], border_color: 'EEEEEE' }) do |t|
          t.row(0).background_color = HEADER_BG
          t.row(-1).background_color = 'E8EEF8'
        end

        @pdf.move_down 8
      end

      def build_retention_detail
        is_federal = @client&.respond_to?(:federal?) && @client.federal?
        sphere_name = @client&.respond_to?(:sphere_name) ? @client.sphere_name : 'Municipal'

        @total_retencoes = @providers_detail.sum { |p| p[:retencao] }.round(2)

        if @total_retencoes > 0
          pct_pecas = is_federal ? '5,85%' : '1,20%'
          pct_serv = is_federal ? '9,45%' : '4,80%'

          ret_pecas = @providers_detail.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:pecas] * 0.0585 : p[:pecas] * 0.012 }
          ret_servicos = @providers_detail.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:servicos] * 0.0945 : p[:servicos] * 0.048 }

          @pdf.font_size 9
          @pdf.text "Retenções Fiscais - #{sphere_name}", style: :bold, color: ORANGE
          @pdf.move_down 3

          ret_data = [
            ["Peças Não-Simples (#{pct_pecas})", "-#{money(ret_pecas)}"],
            ["Serviços Não-Simples (#{pct_serv})", "-#{money(ret_servicos)}"],
            [{ content: "Total Retenções", font_style: :bold }, { content: "-#{money(@total_retencoes)}", font_style: :bold }]
          ]

          @pdf.table(ret_data, width: @pdf.bounds.width * 0.60, position: :right,
                     cell_style: { size: 7.5, padding: [2, 5], borders: [:bottom], border_color: 'EEEEEE' }) do |t|
            t.columns(1).align = :right
            t.column(1).text_color = RED
          end
        else
          @total_retencoes = 0
          @pdf.font_size 8
          @pdf.text "Todos os fornecedores são Simples Nacional - isento de retenção fiscal.", color: GREEN
        end

        @pdf.move_down 6
      end

      def build_provider_retention_table
        is_federal = @client&.respond_to?(:federal?) && @client.federal?
        non_simples = @providers_detail.reject { |p| p[:is_simples] }
        return unless non_simples.any?

        @pdf.font_size 9
        @pdf.text "Detalhamento de Retenção por Fornecedor", style: :bold, color: BLUE_DARK
        @pdf.move_down 3

        header = ['OS', 'Fornecedor', 'CNPJ', '% Peças', 'Ret. Peças', '% Serviços', 'Ret. Serviços', 'Total Ret.']
        det_rows = [header.map { |h| { content: h, font_style: :bold } }]

        ret_pecas_total = 0; ret_servicos_total = 0
        non_simples.each do |p|
          ret_p = is_federal ? p[:pecas] * 0.0585 : p[:pecas] * 0.012
          ret_s = is_federal ? p[:servicos] * 0.0945 : p[:servicos] * 0.048
          ret_pecas_total += ret_p; ret_servicos_total += ret_s
          det_rows << [
            "##{p[:os_code]}", p[:name].to_s.truncate(20), p[:cnpj],
            "#{fmt_pct(p[:pct_pecas])}%", "-#{money(ret_p)}",
            "#{fmt_pct(p[:pct_servicos])}%", "-#{money(ret_s)}",
            "-#{money(p[:retencao])}"
          ]
        end
        det_rows << [
          { content: 'TOTAL:', colspan: 3, font_style: :bold, align: :right },
          '', { content: "-#{money(ret_pecas_total)}", font_style: :bold },
          '', { content: "-#{money(ret_servicos_total)}", font_style: :bold },
          { content: "-#{money(@total_retencoes)}", font_style: :bold }
        ]

        @pdf.table(det_rows, header: true, width: @pdf.bounds.width,
                   cell_style: { size: 7, padding: [2, 3], borders: [:bottom], border_color: 'DDDDDD' }) do |t|
          t.row(0).background_color = HEADER_BG
          t.row(0).size = 7
          t.row(-1).background_color = GRAY_BG
          t.columns(4).align = :right
          t.columns(6..7).align = :right
        end

        @pdf.move_down 6
      end

      def build_valor_devido_bar
        # Valor devido = total com desconto (antes da retencao)
        valor_devido = @total_com_desc

        @pdf.fill_color BLUE_DARK
        bar_y = @pdf.cursor
        @pdf.fill_rectangle [0, bar_y], @pdf.bounds.width, 30
        @pdf.fill_color 'FFFFFF'
        @pdf.font_size 12
        @pdf.text_box "VALOR DEVIDO", at: [12, bar_y - 6], style: :bold, size: 12
        @pdf.text_box money(valor_devido), at: [0, bar_y - 4], width: @pdf.bounds.width - 12,
                      style: :bold, size: 14, align: :right
        @pdf.fill_color '000000'
        @pdf.move_down 36
      end

      def build_observations
        if @fatura.observacoes.present?
          @pdf.font_size 9
          @pdf.text "Observações", style: :bold, color: '666666'
          @pdf.move_down 2
          @pdf.text @fatura.observacoes, size: 8, color: '444444'
          @pdf.move_down 6
        end
      end

      def build_footer
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 4
        @pdf.font_size 7
        @pdf.text "Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} - Frota Insta Solutions",
                  align: :center, color: '999999'
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
