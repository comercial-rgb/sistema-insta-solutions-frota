class GerencialReportController < ApplicationController
  before_action :authorize_access

  def index
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    if params[:start_date].present? || params[:end_date].present?
      @metrics = build_metrics(@start_date, @end_date)
    end

    respond_to do |format|
      format.html
    end
  end

  def export
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    @metrics = build_metrics(@start_date, @end_date)

    respond_to do |format|
      format.xlsx { render_excel }
      format.pdf { render_pdf }
    end
  end

  private

  def authorize_access
    authorize :gerencial_report, :index?
  end

  def build_metrics(start_date, end_date)
    metrics = {}

    # === OS Metrics ===
    os_in_period = OrderService.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    # OS abertas no período (criadas no período)
    metrics[:os_abertas] = os_in_period.count

    # OS respondidas (que chegaram ao status Aprovada, NF inserida, Autorizada, Ag.Pagamento ou Paga no período)
    responded_status_ids = [3, 4, 5, 6, 7] # Aprovada, NF inserida, Autorizada, Ag.Pagamento, Paga
    metrics[:os_respondidas] = OrderService.where(order_service_status_id: responded_status_ids)
                                           .where(updated_at: start_date.beginning_of_day..end_date.end_of_day)
                                           .count

    # OS por status
    metrics[:os_por_status] = OrderService.joins(:order_service_status)
                                          .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                          .group('order_service_statuses.name')
                                          .count
                                          .sort_by { |_, v| -v }

    # === Clientes ===
    metrics[:clientes_ativos] = User.client.active.count
    metrics[:clientes_novos] = User.client.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count

    # === Fornecedores ===
    metrics[:fornecedores_ativos] = User.provider.active.count
    metrics[:fornecedores_novos] = User.provider.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count

    # === Valor aprovado de OS (soma dos valores de propostas aprovadas) ===
    approved_proposals = OrderServiceProposal.joins(:order_service)
                                              .where(order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES)
                                              .where(order_services: { updated_at: start_date.beginning_of_day..end_date.end_of_day })
    metrics[:valor_aprovado_os] = approved_proposals.sum(:total_value).to_f

    # === Faturas ===
    faturas_periodo = Fatura.where(data_emissao: start_date..end_date)
    metrics[:faturas_geradas] = faturas_periodo.count
    metrics[:valor_faturas_geradas] = faturas_periodo.sum(:valor_bruto).to_f
    metrics[:faturas_pagas] = faturas_periodo.pagas.count
    metrics[:valor_faturas_pagas] = faturas_periodo.pagas.sum(:valor_bruto).to_f

    # Faturas vencidas (abertas ou enviadas com vencimento passado)
    faturas_vencidas = Fatura.vencidas
    metrics[:faturas_vencidas] = faturas_vencidas.count
    metrics[:valor_faturas_vencidas] = faturas_vencidas.sum(:valor_bruto).to_f

    # === Contratos ===
    metrics[:contratos_ativos] = Contract.where(active: true).count
    metrics[:contratos_novos] = Contract.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count

    # Clientes com saldo baixo - considerar empenhos e valores realmente consumidos
    low_balance_clients = []
    Contract.where(active: true).includes(:client, :commitments, :addendum_contracts).find_each do |contract|
      total = contract.get_total_value
      next if total.zero?

      # Saldo real = valor total contrato - valor efetivamente consumido por OS (não apenas empenhado)
      total_consumed = 0
      contract.commitments.each do |commitment|
        total_consumed += Commitment.get_total_already_consumed_value(commitment).to_f
      end

      available = total - total_consumed
      pct = (available / total * 100).round(1)
      if pct < 20
        client_name = contract.client&.fantasy_name.presence || contract.client&.social_name.presence || contract.client&.name
        # Também mostrar valor empenhado para referência
        empenhado = contract.get_used_value.to_f
        low_balance_clients << {
          client: client_name,
          contract: contract.name,
          number: contract.number,
          total: total,
          empenhado: empenhado,
          consumed: total_consumed,
          available: available,
          pct: pct
        }
      end
    end
    metrics[:clientes_saldo_baixo] = low_balance_clients.sort_by { |c| c[:pct] }

    # === Contratos com vencimento próximo (30 e 60 dias) ===
    today = Date.current
    contracts_expiring = []
    Contract.where(active: true).includes(:client).find_each do |c|
      next if c.final_date.blank?
      begin
        final = Date.parse(c.final_date.gsub(/(\d{2})\/(\d{2})\/(\d{4})/, '\3-\2-\1'))
      rescue
        next
      end
      days_left = (final - today).to_i
      next unless days_left >= 0 && days_left <= 60
      client_name = c.client&.fantasy_name.presence || c.client&.social_name.presence || c.client&.name
      contracts_expiring << {
        client: client_name,
        contract: c.name,
        number: c.number,
        final_date: final,
        days_left: days_left,
        urgency: days_left <= 30 ? 'danger' : 'warning'
      }
    end
    metrics[:contratos_vencendo] = contracts_expiring.sort_by { |c| c[:days_left] }

    # === Chamados ===
    tickets_periodo = SupportTicket.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    metrics[:chamados_abertos] = tickets_periodo.count
    metrics[:chamados_resolvidos] = SupportTicket.where(
      status: [SupportTicket::STATUS_RESOLVIDO, SupportTicket::STATUS_FECHADO]
    ).where(resolved_at: start_date.beginning_of_day..end_date.end_of_day).count

    metrics
  end

  def render_excel
    require 'caxlsx'

    package = Axlsx::Package.new
    wb = package.workbook

    title_style = wb.styles.add_style(b: true, sz: 14, alignment: { horizontal: :center })
    header_style = wb.styles.add_style(b: true, bg_color: '251C59', fg_color: 'FFFFFF', sz: 11)
    money_style = wb.styles.add_style(num_fmt: 4)
    pct_style = wb.styles.add_style(num_fmt: 10)

    wb.add_worksheet(name: 'Relatório Gerencial') do |sheet|
      sheet.add_row ["Relatório Gerencial - #{@start_date.strftime('%d/%m/%Y')} a #{@end_date.strftime('%d/%m/%Y')}"], style: title_style
      sheet.merge_cells 'A1:D1'
      sheet.add_row []

      # OS
      sheet.add_row ['Indicador', 'Valor'], style: header_style
      sheet.add_row ['OS Abertas no Período', @metrics[:os_abertas]]
      sheet.add_row ['OS Respondidas no Período', @metrics[:os_respondidas]]
      sheet.add_row ['Valor Aprovado de OS', @metrics[:valor_aprovado_os]], style: [nil, money_style]
      sheet.add_row []

      # Clientes e Fornecedores
      sheet.add_row ['Clientes Ativos', @metrics[:clientes_ativos]]
      sheet.add_row ['Clientes Novos no Período', @metrics[:clientes_novos]]
      sheet.add_row ['Fornecedores Ativos', @metrics[:fornecedores_ativos]]
      sheet.add_row ['Fornecedores Novos no Período', @metrics[:fornecedores_novos]]
      sheet.add_row []

      # Faturas
      sheet.add_row ['Faturas Geradas', @metrics[:faturas_geradas]]
      sheet.add_row ['Valor Faturas Geradas', @metrics[:valor_faturas_geradas]], style: [nil, money_style]
      sheet.add_row ['Faturas Pagas', @metrics[:faturas_pagas]]
      sheet.add_row ['Valor Faturas Pagas', @metrics[:valor_faturas_pagas]], style: [nil, money_style]
      sheet.add_row ['Faturas Vencidas', @metrics[:faturas_vencidas]]
      sheet.add_row ['Valor Faturas Vencidas', @metrics[:valor_faturas_vencidas]], style: [nil, money_style]
      sheet.add_row []

      # Contratos
      sheet.add_row ['Contratos Ativos', @metrics[:contratos_ativos]]
      sheet.add_row ['Contratos Novos no Período', @metrics[:contratos_novos]]
      sheet.add_row []

      # Chamados
      sheet.add_row ['Chamados Abertos no Período', @metrics[:chamados_abertos]]
      sheet.add_row ['Chamados Resolvidos no Período', @metrics[:chamados_resolvidos]]
      sheet.add_row []

      # OS por Status
      sheet.add_row ['Status da OS', 'Quantidade'], style: header_style
      @metrics[:os_por_status].each do |status, count|
        sheet.add_row [status, count]
      end
      sheet.add_row []

      # Clientes com saldo baixo
      if @metrics[:clientes_saldo_baixo].any?
        sheet.add_row ['Cliente', 'Contrato', 'Valor Total', 'Empenhado', 'Consumido (OS)', 'Saldo Real', '% Disponível'], style: header_style
        @metrics[:clientes_saldo_baixo].each do |item|
          sheet.add_row [item[:client], "#{item[:contract]} (#{item[:number]})", item[:total], item[:empenhado], item[:consumed], item[:available], item[:pct] / 100.0],
                        style: [nil, nil, money_style, money_style, money_style, money_style, pct_style]
        end
        sheet.add_row []
      end

      # Contratos com vencimento próximo
      if @metrics[:contratos_vencendo].present? && @metrics[:contratos_vencendo].any?
        sheet.add_row ['Cliente', 'Contrato', 'Nº', 'Vencimento', 'Dias Restantes'], style: header_style
        @metrics[:contratos_vencendo].each do |item|
          sheet.add_row [item[:client], item[:contract], item[:number], item[:final_date]&.strftime('%d/%m/%Y'), item[:days_left]]
        end
      end

      sheet.column_widths 35, 20, 20, 20, 20, 20, 15
    end

    send_data package.to_stream.read,
              filename: "relatorio_gerencial_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  def render_pdf
    require 'prawn'
    require 'prawn/table'

    pdf = Prawn::Document.new(page_size: 'A4', margin: 30)

    pdf.font_size 16
    pdf.text "Relatório Gerencial", style: :bold, align: :center
    pdf.font_size 10
    pdf.text "Período: #{@start_date.strftime('%d/%m/%Y')} a #{@end_date.strftime('%d/%m/%Y')}", align: :center
    pdf.move_down 15

    # Helper
    fmt = ->(v) { "R$ #{format('%.2f', v).gsub('.', ',')}" }

    # Main metrics table
    data = [
      ['Indicador', 'Valor'],
      ['OS Abertas no Período', @metrics[:os_abertas].to_s],
      ['OS Respondidas no Período', @metrics[:os_respondidas].to_s],
      ['Valor Aprovado de OS', fmt.call(@metrics[:valor_aprovado_os])],
      ['', ''],
      ['Clientes Ativos', @metrics[:clientes_ativos].to_s],
      ['Clientes Novos no Período', @metrics[:clientes_novos].to_s],
      ['Fornecedores Ativos', @metrics[:fornecedores_ativos].to_s],
      ['Fornecedores Novos no Período', @metrics[:fornecedores_novos].to_s],
      ['', ''],
      ['Faturas Geradas', @metrics[:faturas_geradas].to_s],
      ['Valor Faturas Geradas', fmt.call(@metrics[:valor_faturas_geradas])],
      ['Faturas Pagas', @metrics[:faturas_pagas].to_s],
      ['Valor Faturas Pagas', fmt.call(@metrics[:valor_faturas_pagas])],
      ['Faturas Vencidas', @metrics[:faturas_vencidas].to_s],
      ['Valor Faturas Vencidas', fmt.call(@metrics[:valor_faturas_vencidas])],
      ['', ''],
      ['Contratos Ativos', @metrics[:contratos_ativos].to_s],
      ['Contratos Novos no Período', @metrics[:contratos_novos].to_s],
      ['', ''],
      ['Chamados Abertos no Período', @metrics[:chamados_abertos].to_s],
      ['Chamados Resolvidos no Período', @metrics[:chamados_resolvidos].to_s],
    ]

    pdf.table(data, width: pdf.bounds.width) do |t|
      t.row(0).background_color = '251C59'
      t.row(0).text_color = 'FFFFFF'
      t.row(0).font_style = :bold
      t.cells.padding = [4, 8]
      t.cells.size = 9
      t.column(0).width = 300
    end

    pdf.move_down 15

    # OS por Status
    if @metrics[:os_por_status].any?
      pdf.font_size 12
      pdf.text "OS por Status", style: :bold
      pdf.move_down 5

      status_data = [['Status', 'Quantidade']] + @metrics[:os_por_status].map { |s, c| [s, c.to_s] }
      pdf.table(status_data, width: 300) do |t|
        t.row(0).background_color = '251C59'
        t.row(0).text_color = 'FFFFFF'
        t.row(0).font_style = :bold
        t.cells.padding = [3, 6]
        t.cells.size = 9
      end
    end

    pdf.move_down 15

    # Low balance clients
    if @metrics[:clientes_saldo_baixo].any?
      pdf.font_size 12
      pdf.text "Clientes com Saldo Baixo (< 20%)", style: :bold
      pdf.move_down 5

      low_data = [['Cliente', 'Contrato', 'Total', 'Empenhado', 'Consumido', 'Saldo', '%']]
      @metrics[:clientes_saldo_baixo].each do |item|
        low_data << [item[:client], item[:contract], fmt.call(item[:total]), fmt.call(item[:empenhado]), fmt.call(item[:consumed]), fmt.call(item[:available]), "#{item[:pct]}%"]
      end

      pdf.table(low_data, width: pdf.bounds.width) do |t|
        t.row(0).background_color = '251C59'
        t.row(0).text_color = 'FFFFFF'
        t.row(0).font_style = :bold
        t.cells.padding = [3, 6]
        t.cells.size = 7
      end
    end

    pdf.move_down 15

    # Contracts expiring
    if @metrics[:contratos_vencendo].present? && @metrics[:contratos_vencendo].any?
      pdf.font_size 12
      pdf.text "Contratos com Vencimento em até 60 dias", style: :bold
      pdf.move_down 5

      exp_data = [['Cliente', 'Contrato', 'Vencimento', 'Dias']]
      @metrics[:contratos_vencendo].each do |item|
        exp_data << [item[:client], item[:contract], item[:final_date]&.strftime('%d/%m/%Y'), item[:days_left].to_s]
      end

      pdf.table(exp_data, width: pdf.bounds.width) do |t|
        t.row(0).background_color = '251C59'
        t.row(0).text_color = 'FFFFFF'
        t.row(0).font_style = :bold
        t.cells.padding = [3, 6]
        t.cells.size = 8
      end
    end

    send_data pdf.render,
              filename: "relatorio_gerencial_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end
end
