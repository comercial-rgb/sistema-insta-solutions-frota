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
      HEADER_BG  = 'E8E8E8'

      def initialize(fatura)
        @fatura = fatura
        @client = fatura.client
        @items = fatura.fatura_itens.includes(
          order_service: [:vehicle, :cost_center, :sub_unit,
            { order_service_proposals: [:provider, :order_service_invoices] }]
        )
      end

      def call
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}_#{timestamp}.pdf"
        output_path = Rails.root.join('tmp', output_filename)

        Prawn::Document.generate(output_path.to_s, page_size: 'A4', margin: [30, 30, 30, 30]) do |pdf|
          @pdf = pdf
          pdf.font 'Helvetica'

          build_header
          build_client_block
          build_contract_info
          build_items_table
          build_financial_summary
          build_retention_detail
          build_valor_devido_bar
          build_observations
          build_footer
        end

        output_path.to_s
      end

      private

      def build_header
        @pdf.font_size 16
        @pdf.text "FATURA DE SERVIÇOS", style: :bold, align: :center, color: BLUE_DARK
        @pdf.move_down 3
        @pdf.font_size 12
        @pdf.text "Nº #{@fatura.numero}", style: :bold, align: :center, color: BLUE_LIGHT
        @pdf.move_down 8

        @pdf.font_size 9
        data_table = [
          [
            { content: "Emissão: #{fmt_date(@fatura.data_emissao)}", align: :left },
            { content: "Vencimento: #{fmt_date(@fatura.data_vencimento)}", align: :center },
            { content: "Status: #{@fatura.status.upcase}", align: :right }
          ]
        ]
        @pdf.table(data_table, width: @pdf.bounds.width, cell_style: { borders: [], padding: [2, 4], size: 9 })
        @pdf.move_down 4
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 8
      end

      def build_client_block
        @pdf.font_size 10
        @pdf.text "GERENCIADA / CLIENTE", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        client_name = @client&.fantasy_name.presence || @client&.social_name.presence || @client&.name || '-'
        cnpj = @client&.cnpj || '-'
        address = @client&.respond_to?(:get_address) ? @client.get_address : '-'
        city = @client&.respond_to?(:get_city) ? @client.get_city : ''
        state = @client&.respond_to?(:get_state) ? @client.get_state : ''
        phone = @client&.phone || '-'
        email = @client&.email || '-'
        sphere = @client&.respond_to?(:sphere_name) ? @client.sphere_name : '-'

        info_data = [
          ["Razão Social: #{client_name}", "CNPJ: #{cnpj}"],
          ["Endereço: #{address}", "Cidade/UF: #{city}/#{state}"],
          ["Telefone: #{phone}", "E-mail: #{email}"],
          ["Esfera: #{sphere}", "Desconto Contrato: #{fmt_pct(@client&.discount_percent)}%"]
        ]

        @pdf.table(info_data, width: @pdf.bounds.width,
                   cell_style: { size: 8, padding: [1, 4], borders: [] })
        @pdf.move_down 8
        @pdf.stroke_color 'CCCCCC'
        @pdf.stroke_horizontal_rule
        @pdf.move_down 8
      end

      def build_contract_info
        contract_number = @fatura.contract&.number
        cc_name = @fatura.cost_center&.name
        su_name = @fatura.sub_unit&.respond_to?(:name) ? @fatura.sub_unit.name : nil

        return unless contract_number || cc_name

        @pdf.font_size 8
        parts = []
        parts << "Contrato: #{contract_number}" if contract_number
        parts << "Centro de Custo: #{cc_name}" if cc_name
        parts << "Sub-unidade: #{su_name}" if su_name.present?
        @pdf.text parts.join('  |  '), color: '666666'
        @pdf.move_down 8
      end

      def build_items_table
        @pdf.font_size 9
        @pdf.text "ITENS DA FATURA", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        header = ['OS', 'Fornecedor', 'Veículo', 'C.Custo', 'Peças (NF)', 'Serviços (NF)', 'V.Bruto', 'Desc.', 'V.c/Desc.']
        rows = [header.map { |h| { content: h, font_style: :bold } }]

        @total_pecas = 0
        @total_servicos = 0
        @total_bruto = 0
        @total_desconto = 0
        @total_com_desc = 0
        @providers_info = []

        client_discount_pct = (@client&.discount_percent || 0).to_d / 100

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

          pecas_nums = nf_pecas.map(&:number).compact.join(', ')
          servicos_nums = nf_servicos.map(&:number).compact.join(', ')

          provider = proposal.provider
          is_simples = provider ? !provider.optante_simples : true
          regime = is_simples ? 'Simples' : 'Não-Simples'

          @total_pecas += pecas_val
          @total_servicos += servicos_val
          @total_bruto += bruto
          @total_desconto += desc_val
          @total_com_desc += com_desc

          @providers_info << {
            name: provider&.get_name || '-',
            cnpj: provider&.cnpj || '-',
            is_simples: is_simples,
            nf_pecas_val: nf_pecas.sum(&:value).to_f,
            nf_servicos_val: nf_servicos.sum(&:value).to_f
          }

          pct = bruto > 0 ? ((desc_val / bruto) * 100).round(2) : 0

          rows << [
            "##{os.code}",
            "#{provider&.get_name&.truncate(18) || '-'}\n(#{regime})",
            os.vehicle&.board || '-',
            (os.cost_center&.name || '-').truncate(15),
            "#{money(pecas_val)}#{pecas_nums.present? ? "\n(NF #{pecas_nums})" : ''}",
            "#{money(servicos_val)}#{servicos_nums.present? ? "\n(NF #{servicos_nums})" : ''}",
            money(bruto),
            "-#{money(desc_val)}\n(#{fmt_pct(pct)}%)",
            money(com_desc)
          ]
        end

        rows << [
          { content: 'SUBTOTAIS:', colspan: 4, font_style: :bold, align: :right },
          { content: money(@total_pecas), font_style: :bold, align: :right },
          { content: money(@total_servicos), font_style: :bold, align: :right },
          { content: money(@total_bruto), font_style: :bold, align: :right },
          { content: "-#{money(@total_desconto)}", font_style: :bold, align: :right, text_color: RED },
          { content: money(@total_com_desc), font_style: :bold, align: :right, text_color: GREEN }
        ]

        if rows.length > 2
          col_widths = [35, 85, 45, 55, 65, 65, 55, 55, 55]
          @pdf.table(rows, header: true, width: @pdf.bounds.width,
                     column_widths: col_widths,
                     cell_style: { size: 6.5, padding: [3, 3], borders: [:bottom], border_color: 'DDDDDD' }) do |t|
            t.row(0).background_color = HEADER_BG
            t.row(0).size = 7
            t.row(-1).background_color = GRAY_BG
            t.columns(4..8).align = :right
          end
        else
          @pdf.text "Nenhum item encontrado.", style: :italic, size: 8
        end

        @pdf.move_down 10
      end

      def build_financial_summary
        @pdf.font_size 9
        @pdf.text "RESUMO FINANCEIRO", style: :bold, color: BLUE_DARK
        @pdf.move_down 4

        pct_desc = @total_bruto > 0 ? ((@total_desconto / @total_bruto) * 100).round(2) : 0
        desc_pecas = @total_pecas * (@client&.discount_percent || 0).to_d / 100
        desc_servicos = @total_servicos * (@client&.discount_percent || 0).to_d / 100

        data = [
          ['', 'Peças', 'Serviços', 'Total'],
          ['Valor sem desconto', money(@total_pecas), money(@total_servicos), money(@total_bruto)],
          ["(-) Desconto (#{fmt_pct(pct_desc)}%)", "-#{money(desc_pecas)}", "-#{money(desc_servicos)}", "-#{money(@total_desconto)}"],
          ['Valor c/ Desconto', money(@total_pecas - desc_pecas), money(@total_servicos - desc_servicos), money(@total_com_desc)]
        ]

        @pdf.table(data, width: @pdf.bounds.width * 0.65, position: :right,
                   cell_style: { size: 7.5, padding: [3, 5], borders: [:bottom], border_color: 'EEEEEE' }) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = HEADER_BG
          t.columns(1..3).align = :right
          t.row(-1).font_style = :bold
          t.row(2).text_color = RED
        end

        @pdf.move_down 8
      end

      def build_retention_detail
        is_federal = @client&.respond_to?(:federal?) && @client.federal?
        sphere_name = @client&.respond_to?(:sphere_name) ? @client.sphere_name : 'Municipal'

        total_ret = 0
        @providers_info.each do |p|
          next if p[:is_simples]
          if is_federal
            total_ret += p[:nf_pecas_val] * 0.0585
            total_ret += p[:nf_servicos_val] * 0.0945
          else
            total_ret += p[:nf_pecas_val] * 0.012
            total_ret += p[:nf_servicos_val] * 0.048
          end
        end
        @total_retencoes = total_ret.round(2)

        if @total_retencoes > 0
          @pdf.font_size 8
          @pdf.text "RETENÇÕES FISCAIS (#{sphere_name})", style: :bold, color: ORANGE
          @pdf.move_down 3

          pct_pecas = is_federal ? '5,85%' : '1,20%'
          pct_serv = is_federal ? '9,45%' : '4,80%'
          detail_pecas = is_federal ? 'IR 1,2% + CSLL 1% + PIS 0,65% + Cofins 3%' : 'somente IR'
          detail_serv = is_federal ? 'IR 4,8% + CSLL 1% + PIS 0,65% + Cofins 3%' : 'somente IR'

          ret_pecas = @providers_info.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:nf_pecas_val] * 0.0585 : p[:nf_pecas_val] * 0.012 }
          ret_servicos = @providers_info.reject { |p| p[:is_simples] }.sum { |p| is_federal ? p[:nf_servicos_val] * 0.0945 : p[:nf_servicos_val] * 0.048 }

          ret_data = [
            ["Peças Não-Simples (#{pct_pecas} - #{detail_pecas})", "-#{money(ret_pecas)}"],
            ["Serviços Não-Simples (#{pct_serv} - #{detail_serv})", "-#{money(ret_servicos)}"],
            [{ content: "Total Retenções", font_style: :bold }, { content: "-#{money(@total_retencoes)}", font_style: :bold }]
          ]

          @pdf.table(ret_data, width: @pdf.bounds.width * 0.65, position: :right,
                     cell_style: { size: 7, padding: [2, 5], borders: [:bottom], border_color: 'EEEEEE' }) do |t|
            t.columns(1).align = :right
            t.column(1).text_color = RED
          end
        else
          @total_retencoes = 0
          @pdf.font_size 8
          @pdf.text "Todos os fornecedores são Simples Nacional — isento de retenção fiscal.", color: GREEN
        end

        @pdf.move_down 8
      end

      def build_valor_devido_bar
        valor_devido = @total_com_desc - @total_retencoes

        @pdf.fill_color BLUE_DARK
        bar_y = @pdf.cursor
        @pdf.fill_rectangle [0, bar_y], @pdf.bounds.width, 28
        @pdf.fill_color 'FFFFFF'
        @pdf.font_size 11
        @pdf.text_box "VALOR DEVIDO", at: [10, bar_y - 6], style: :bold, size: 11
        @pdf.text_box money(valor_devido), at: [0, bar_y - 5], width: @pdf.bounds.width - 10,
                      style: :bold, size: 13, align: :right
        @pdf.fill_color '000000'
        @pdf.move_down 35
      end

      def build_observations
        if @fatura.observacoes.present?
          @pdf.font_size 8
          @pdf.text "OBSERVAÇÕES", style: :bold, color: '666666'
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
        @pdf.text "Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} — Frota Insta Solutions",
                  align: :center, color: '999999'
        @pdf.text "Este documento não possui valor fiscal.", align: :center, color: '999999'
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
