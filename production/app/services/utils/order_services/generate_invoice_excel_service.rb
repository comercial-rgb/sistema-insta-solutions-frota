require 'spreadsheet'

module Utils
  module OrderServices
    class GenerateInvoiceExcelService
      def initialize(fatura)
        @fatura = fatura
        @client = fatura.client
        @items = fatura.fatura_itens.includes(order_service: [:vehicle, :cost_center, :sub_unit,
                   { order_service_proposals: [:provider, :order_service_invoices] }])
      end

      def call
        timestamp = Time.now.strftime('%Y%m%d%H%M%S%L')
        output_filename = "fatura_#{@fatura.numero.parameterize}_#{timestamp}.xls"
        output_path = Rails.root.join('public', output_filename)

        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet(name: "Fatura #{@fatura.numero}")

        # Formatos
        fmt_title = Spreadsheet::Format.new(weight: :bold, size: 14)
        fmt_header = Spreadsheet::Format.new(weight: :bold, size: 9, pattern: 1,
                                              pattern_fg_color: :silver, border: :thin)
        fmt_bold = Spreadsheet::Format.new(weight: :bold, size: 10)
        fmt_money = Spreadsheet::Format.new(number_format: '#,##0.00', size: 9)
        fmt_money_bold = Spreadsheet::Format.new(number_format: '#,##0.00', size: 10, weight: :bold)
        fmt_normal = Spreadsheet::Format.new(size: 9)

        row = 0

        # Header
        sheet.row(row).default_format = fmt_title
        sheet[row, 0] = "FATURA #{@fatura.numero}"
        row += 1
        sheet.row(row).default_format = fmt_normal
        sheet[row, 0] = "Emissão: #{@fatura.data_emissao&.strftime('%d/%m/%Y')}"
        sheet[row, 2] = "Vencimento: #{@fatura.data_vencimento&.strftime('%d/%m/%Y')}"
        row += 1
        sheet[row, 0] = "Cliente: #{@client&.fantasy_name.presence || @client&.social_name.presence || @client&.name || '-'}"
        sheet[row, 2] = "CNPJ: #{@client&.cnpj || '-'}"
        row += 2

        # Items header
        headers = ['OS', 'Veículo', 'Centro de Custo', 'Fornecedor', 'CNPJ Forn.',
                   'NF Peças', 'Valor Peças', 'NF Serviços', 'Valor Serviços',
                   'Valor Bruto', 'Desconto', 'Valor c/ Desconto']
        headers.each_with_index do |h, i|
          sheet.row(row).set_format(i, fmt_header)
          sheet[row, i] = h
        end
        row += 1

        # Items
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

          sheet.row(row).default_format = fmt_normal
          sheet[row, 0] = os.code.to_s
          sheet[row, 1] = os.vehicle&.board || '-'
          sheet[row, 2] = os.cost_center&.name || '-'
          sheet[row, 3] = proposal.provider&.get_name || '-'
          sheet[row, 4] = proposal.provider&.cnpj || '-'
          sheet[row, 5] = nf_pecas.map(&:number).compact.join(', ')
          sheet.row(row).set_format(6, fmt_money)
          sheet[row, 6] = nf_pecas.sum(&:value).to_f
          sheet[row, 7] = nf_servicos.map(&:number).compact.join(', ')
          sheet.row(row).set_format(8, fmt_money)
          sheet[row, 8] = nf_servicos.sum(&:value).to_f
          sheet.row(row).set_format(9, fmt_money)
          sheet[row, 9] = proposal.total_value_without_discount.to_f
          sheet.row(row).set_format(10, fmt_money)
          sheet[row, 10] = proposal.total_discount.to_f
          sheet.row(row).set_format(11, fmt_money)
          sheet[row, 11] = proposal.total_value.to_f
          row += 1
        end

        row += 1

        # Resumo financeiro
        sheet.row(row).default_format = fmt_bold
        sheet[row, 0] = 'RESUMO FINANCEIRO'
        row += 1

        summary = [
          ['Valor Bruto', @fatura.valor_bruto.to_f],
          ['(-) Desconto', @fatura.desconto.to_f],
          ['Valor c/ Desconto', @fatura.valor_liquido.to_f],
          ['(-) Retenções', @fatura.total_retencoes.to_f],
          ['VALOR DEVIDO', @fatura.valor_final.to_f]
        ]

        summary.each do |label, val|
          is_last = label == 'VALOR DEVIDO'
          fmt = is_last ? fmt_money_bold : fmt_money
          lbl_fmt = is_last ? fmt_bold : fmt_normal
          sheet.row(row).set_format(0, lbl_fmt)
          sheet[row, 0] = label
          sheet.row(row).set_format(1, fmt)
          sheet[row, 1] = val
          row += 1
        end

        if @fatura.observacoes.present?
          row += 1
          sheet.row(row).default_format = fmt_bold
          sheet[row, 0] = 'Observações'
          row += 1
          sheet[row, 0] = @fatura.observacoes
        end

        # Column widths
        [8, 12, 18, 22, 18, 12, 14, 12, 14, 14, 12, 14].each_with_index do |w, i|
          sheet.column(i).width = w
        end

        book.write(output_path.to_s)
        output_path.to_s
      end
    end
  end
end
