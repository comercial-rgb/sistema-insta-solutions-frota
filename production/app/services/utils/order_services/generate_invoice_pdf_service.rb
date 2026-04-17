require 'prawn'
require 'prawn/table'

module Utils
  module OrderServices
    class GenerateInvoicePdfService
      def initialize(fatura)
        @fatura = fatura
        @client = fatura.client
        @items = fatura.fatura_itens.includes(order_service: [:vehicle, :cost_center, :sub_unit,
                   { order_service_proposals: [:provider, :order_service_invoices] }])
      end

      def call
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}_#{timestamp}.pdf"
        output_path = Rails.root.join('public', output_filename)

        Prawn::Document.generate(output_path.to_s, page_size: 'A4', margin: [40, 40, 40, 40]) do |pdf|
          build_header(pdf)
          build_client_info(pdf)
          build_items_table(pdf)
          build_financial_summary(pdf)
          build_footer(pdf)
        end

        output_path.to_s
      end

      private

      def build_header(pdf)
        pdf.font_size 18
        pdf.text "FATURA #{@fatura.numero}", style: :bold, align: :center
        pdf.move_down 5
        pdf.font_size 10
        pdf.text "Data de Emissão: #{@fatura.data_emissao&.strftime('%d/%m/%Y')}", align: :center
        pdf.text "Data de Vencimento: #{@fatura.data_vencimento&.strftime('%d/%m/%Y')}", align: :center
        pdf.move_down 15
        pdf.stroke_horizontal_rule
        pdf.move_down 10
      end

      def build_client_info(pdf)
        pdf.font_size 10
        pdf.text "CLIENTE", style: :bold
        pdf.text @client&.fantasy_name.presence || @client&.social_name.presence || @client&.name || '-'
        pdf.text "CNPJ: #{@client&.cnpj || '-'}"

        if @fatura.cost_center.present?
          pdf.text "Centro de Custo: #{@fatura.cost_center.name}"
        end
        if @fatura.contract.present?
          pdf.text "Contrato: #{@fatura.contract.number}"
        end

        pdf.move_down 10
        pdf.stroke_horizontal_rule
        pdf.move_down 10
      end

      def build_items_table(pdf)
        pdf.font_size 9
        pdf.text "ITENS DA FATURA", style: :bold
        pdf.move_down 5

        header = ['OS', 'Veículo', 'C. Custo', 'Fornecedor', 'Peças (NF)', 'Serviços (NF)', 'V. Bruto']
        rows = [header]

        @items.each do |item|
          os = item.order_service
          next unless os

          proposal = os.order_service_proposals
                       .where(order_service_proposal_status_id: [
                         OrderServiceProposalStatus::AUTORIZADA_ID,
                         OrderServiceProposalStatus::APROVADA_ID
                       ].compact)
                       .order(updated_at: :desc).first
          next unless proposal

          invoices = proposal.order_service_invoices.to_a
          nf_pecas = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }
          nf_servicos = invoices.select { |i| i.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }

          pecas_val = nf_pecas.sum(&:value).to_f
          servicos_val = nf_servicos.sum(&:value).to_f
          pecas_nums = nf_pecas.map(&:number).compact.join(', ')
          servicos_nums = nf_servicos.map(&:number).compact.join(', ')

          rows << [
            "##{os.code}",
            os.vehicle&.board || '-',
            os.cost_center&.name || '-',
            proposal.provider&.get_name&.truncate(25) || '-',
            "#{money(pecas_val)}#{pecas_nums.present? ? "\n(NF #{pecas_nums})" : ''}",
            "#{money(servicos_val)}#{servicos_nums.present? ? "\n(NF #{servicos_nums})" : ''}",
            money(proposal.total_value_without_discount.to_f)
          ]
        end

        if rows.length > 1
          pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 7, padding: [3, 4] }) do |t|
            t.row(0).font_style = :bold
            t.row(0).background_color = 'DDDDDD'
            t.columns(4..6).align = :right
          end
        else
          pdf.text "Nenhum item encontrado.", style: :italic
        end

        pdf.move_down 15
      end

      def build_financial_summary(pdf)
        pdf.font_size 10
        pdf.text "RESUMO FINANCEIRO", style: :bold
        pdf.move_down 5

        data = [
          ['Valor Bruto:', money(@fatura.valor_bruto)],
          ['(-) Desconto:', "- #{money(@fatura.desconto)}"],
          ['Valor c/ Desconto:', money(@fatura.valor_liquido)],
          ['(-) Retenções:', "- #{money(@fatura.total_retencoes)}"],
          ['VALOR DEVIDO:', money(@fatura.valor_final)]
        ]

        pdf.table(data, width: 300, position: :right, cell_style: { size: 9, padding: [4, 8] }) do |t|
          t.columns(1).align = :right
          t.row(-1).font_style = :bold
          t.row(-1).background_color = 'E8F5E9'
        end

        pdf.move_down 10

        if @fatura.observacoes.present?
          pdf.text "Observações:", style: :bold
          pdf.text @fatura.observacoes
          pdf.move_down 10
        end
      end

      def build_footer(pdf)
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.font_size 7
        pdf.text "Documento gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')} — Frota Insta Solutions", align: :center, color: '999999'
      end

      def money(val)
        "R$ #{format('%.2f', val.to_f).gsub('.', ',').gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')}"
      end
    end
  end
end
