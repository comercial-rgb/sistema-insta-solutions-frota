class CustomReportsController < ApplicationController
  require 'prawn/table' if defined?(Prawn)
  include ActionView::Helpers::NumberHelper
  
  before_action :authorize_access

  def index
    # Buscar clientes (Users com perfil de cliente)
    if @current_user.admin?
      @clients = User.client.active.name_ordered
    else
      # Gestor/Adicional vê apenas seu próprio cliente
      @clients = User.client.active.where(id: @current_user.client_id).name_ordered
    end

    @clients_options = @clients.map do |client|
      social_name = client.social_name.to_s.strip
      fantasy_name = client.fantasy_name.to_s.strip
      fallback_name = client.name.to_s.strip

      label = if social_name.present? && fantasy_name.present?
        "#{social_name} (#{fantasy_name})"
      else
        social_name.presence || fantasy_name.presence || fallback_name
      end

      [label, client.id]
    end

    selected_client_id = if @current_user.admin?
      params[:client_id]
    else
      @current_user.client_id
    end

    @selected_client = User.client.active.find_by(id: selected_client_id) if selected_client_id.present?
    
    # Carregar coleções para filtros
    @providers = User.provider.order(:fantasy_name)
    @cost_centers = if @current_user.admin?
      CostCenter.order(:name)
    elsif @current_user.manager? || @current_user.additional?
      CostCenter.by_client_id(@current_user.client_id).order(:name)
    else
      CostCenter.none
    end
    @sub_units = if @current_user.admin?
      SubUnit.order(:name)
    elsif @current_user.manager? || @current_user.additional?
      SubUnit.by_client_id(@current_user.client_id).order(:name)
    else
      SubUnit.none
    end
    @vehicles = if @current_user.admin?
      Vehicle.order(:board)
    else
      Vehicle.getting_data_by_user(@current_user)
    end
    @commitments = if @current_user.admin?
      Commitment.where(active: true).order(:commitment_number)
    elsif @current_user.manager? || @current_user.additional?
      Commitment.where(active: true, client_id: @current_user.client_id).order(:commitment_number)
    else
      Commitment.none
    end
    
    # Inicializar como vazio se não houver filtros
    if has_filters?
      @order_services = apply_filters(policy_scope(OrderService))
    else
      @order_services = OrderService.none
    end
    
    respond_to do |format|
      format.html
      format.pdf do
        if params[:report_type] == 'demonstrativo'
          render_demonstrativo_pdf
        else
          render_pdf
        end
      end
      format.csv { render_csv }
    end
  end

  def provider_report
    authorize :custom_report, :index?

    if @current_user.admin?
      @clients = User.client.active.name_ordered
    else
      @clients = User.client.active.where(id: @current_user.client_id).name_ordered
    end

    @clients_options = @clients.map do |client|
      social_name = client.social_name.to_s.strip
      fantasy_name = client.fantasy_name.to_s.strip
      fallback_name = client.name.to_s.strip
      label = if social_name.present? && fantasy_name.present?
        "#{social_name} (#{fantasy_name})"
      else
        social_name.presence || fantasy_name.presence || fallback_name
      end
      [label, client.id]
    end

    selected_client_id = @current_user.admin? ? params[:client_id] : @current_user.client_id
    @selected_client = User.client.active.find_by(id: selected_client_id) if selected_client_id.present?

    @provider_rows = []
    @grand_total_transactions = 0
    @grand_total_gross        = 0.0
    @grand_total_net          = 0.0

    if selected_client_id.present? || !@current_user.admin?
      valid_statuses = [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ]

      base = OrderServiceProposal
        .joins(:order_service)
        .joins("INNER JOIN users AS providers ON providers.id = order_service_proposals.provider_id")
        .where(is_complement: false)
        .where(order_service_proposal_status_id: valid_statuses)

      if selected_client_id.present?
        base = base.where(order_services: { client_id: selected_client_id })
      elsif @current_user.manager? || @current_user.additional?
        base = base.where(order_services: { client_id: @current_user.client_id })
      end

      if params[:start_date].present?
        start_date = Date.parse(params[:start_date]) rescue nil
        base = base.where("order_service_proposals.created_at >= ?", start_date.beginning_of_day) if start_date
      end
      if params[:end_date].present?
        end_date = Date.parse(params[:end_date]) rescue nil
        base = base.where("order_service_proposals.created_at <= ?", end_date.end_of_day) if end_date
      end

      rows = base
        .group("order_service_proposals.provider_id, providers.fantasy_name, providers.social_name, providers.name")
        .select(
          "order_service_proposals.provider_id",
          "providers.fantasy_name AS provider_fantasy_name",
          "providers.social_name AS provider_social_name",
          "providers.name AS provider_name",
          "COUNT(order_service_proposals.id) AS transactions_count",
          "SUM(order_service_proposals.total_value_without_discount) AS gross_value",
          "SUM(order_service_proposals.total_value) AS net_value"
        )
        .order("net_value DESC")

      @grand_total_gross = rows.sum { |r| r.gross_value.to_f }
      @grand_total_net   = rows.sum { |r| r.net_value.to_f }
      @grand_total_transactions = rows.sum { |r| r.transactions_count.to_i }

      @provider_rows = rows.map do |r|
        net = r.net_value.to_f
        pct = @grand_total_net > 0 ? ((net / @grand_total_net) * 100).round(2) : 0.0
        {
          name: r.provider_fantasy_name.presence || r.provider_social_name.presence || r.provider_name || 'Sem nome',
          transactions: r.transactions_count.to_i,
          gross_value: r.gross_value.to_f,
          net_value: net,
          pct: pct
        }
      end
    end

    respond_to do |format|
      format.html
      format.pdf { render_provider_report_pdf }
      format.csv { render_provider_report_csv }
    end
  end

  private

  def has_filters?
    params[:client_id].present? || params[:start_date].present? || 
    params[:month].present? || params[:year].present? ||
    params[:status_id].present? || params[:type_id].present? ||
    params[:vehicle_id].present? || params[:provider_id].present? ||
    params[:cost_center_id].present? || params[:sub_unit_id].present? ||
    params[:commitment_id].present?
  end

  def authorize_access
    authorize :custom_report, :index?
  end

  def apply_filters(scope)
    # O default_scope já inclui client, status, vehicle, então não precisa duplicar
    # Eager load vehicle para evitar N+1 queries
    scope = scope.includes(:vehicle, :order_service_status, :order_service_type)
    
    # Aplicar filtro de permissões SEMPRE (mesmo para admin)
    if @current_user.manager? || @current_user.additional?
      # Gestor e Adicional veem apenas OS do seu cliente
      scope = scope.where(client_id: @current_user.client_id)
    end
    
    # Filtro por cliente
    if params[:client_id].present?
      scope = scope.where(client_id: params[:client_id])
    end
    
    # Determinar o range de data a ser usado
    date_range = nil
    
    # Prioridade: Data Inicial/Final > Mês/Ano
    if params[:start_date].present? || params[:end_date].present?
      start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
      end_date = params[:end_date].present? ? (Date.parse(params[:end_date]) rescue nil) : nil
      
      if start_date && end_date
        date_range = start_date.beginning_of_day..end_date.end_of_day
      elsif start_date
        date_range = start_date.beginning_of_day..DateTime.now.end_of_day
      elsif end_date
        date_range = DateTime.new(2000,1,1)..end_date.end_of_day
      end
    elsif params[:month].present? && params[:year].present?
      month = params[:month].to_i
      year = params[:year].to_i
      date_range = Date.new(year, month, 1).beginning_of_day..Date.new(year, month, 1).end_of_month.end_of_day
    elsif params[:year].present?
      year = params[:year].to_i
      date_range = Date.new(year, 1, 1).beginning_of_day..Date.new(year, 12, 31).end_of_day
    end

    # Se há status + datas: busca por auditoria (OS que PASSARAM por aquele status no período)
    # Isso permite encontrar OS autorizadas em Dez/2025 mesmo que agora estejam em "Paga"
    if params[:status_id].present? && date_range.present?
      scope = scope
        .left_outer_joins(:audits)
        .where(audits: { auditable_type: 'OrderService' })
        .where(audits: { associated_id: params[:status_id] })
        .where(audits: { created_at: date_range })
        .distinct
    else
      # Sem status: filtra por created_at
      if date_range.present?
        scope = scope.where(created_at: date_range)
      end

      if params[:status_id].present?
        scope = scope.where(order_service_status_id: params[:status_id])
      end
    end
    
    # Filtro por tipo de OS
    if params[:type_id].present?
      scope = scope.where(order_service_type_id: params[:type_id])
    end
    
    # Filtro por veículo
    if params[:vehicle_id].present?
      scope = scope.where(vehicle_id: params[:vehicle_id])
    end
    
    # Filtro por fornecedor (busca OS que têm propostas deste fornecedor OU foram atribuídas a ele)
    if params[:provider_id].present?
      scope = scope.left_outer_joins(:order_service_proposals)
                   .where("order_service_proposals.provider_id = :pid OR order_services.provider_id = :pid", pid: params[:provider_id])
                   .distinct
    end
    
    # Filtro por centro de custo (via veículo)
    if params[:cost_center_id].present?
      scope = scope.joins(:vehicle).where(vehicles: { cost_center_id: params[:cost_center_id] })
    end
    
    # Filtro por subunidade (via veículo)
    if params[:sub_unit_id].present?
      scope = scope.joins(:vehicle).where(vehicles: { sub_unit_id: params[:sub_unit_id] })
    end

    # Filtro por empenho (cobre empenho geral, de peças e de serviços)
    if params[:commitment_id].present?
      cid = params[:commitment_id].to_i
      scope = scope.where(
        'order_services.commitment_id = :cid OR order_services.commitment_parts_id = :cid OR order_services.commitment_services_id = :cid',
        cid: cid
      )
    end

    scope.order(created_at: :desc)
  end

  def render_pdf
    pdf = generate_pdf_report(
      @order_services,
      selected_client: @selected_client,
      report_params: params.to_unsafe_h
    )
    send_data pdf.render,
              filename: "relatorio_personalizado_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  def render_demonstrativo_pdf
    tempfiles_to_cleanup = []

    pdf = Prawn::Document.new(page_size: 'A4', page_layout: :landscape) do |pdf|
      pdf.font_size 10

      # --- Logo ---
      logo_path = Rails.root.join('app', 'assets', 'images', 'logos', 'logo.png')
      logo_drawn = false
      if File.exist?(logo_path)
        begin
          pdf.image logo_path.to_s, fit: [160, 50], position: :left
          logo_drawn = true
        rescue Prawn::Errors::UnsupportedImageType, Prawn::Errors::UnsupportedImageFormat
          begin
            require 'mini_magick'
            tmp = Tempfile.new(['instasolutions-logo', '.png'])
            tmp.binmode
            image = MiniMagick::Image.open(logo_path.to_s)
            begin; image.interlace 'none'; rescue StandardError; end
            image.format 'png'
            image.write tmp.path
            tempfiles_to_cleanup << tmp
            pdf.image tmp.path, fit: [160, 50], position: :left
            logo_drawn = true
          rescue StandardError
            logo_drawn = false
          end
        end
      end
      pdf.text 'InstaSolutions', size: 16, style: :bold unless logo_drawn

      pdf.move_down 10
      pdf.text 'DEMONSTRATIVO DE FATURAMENTO', size: 16, style: :bold, align: :center
      pdf.move_down 5

      if @selected_client.present?
        client_name = @selected_client.fantasy_name.presence || @selected_client.name
        pdf.text "Cliente: #{client_name}", size: 11
      end
      pdf.text "Data de emissão: #{Date.current.strftime('%d/%m/%Y')}", size: 10
      pdf.move_down 10

      # --- Tabela ---
      header = ['ID', 'Placa', 'Modelo', 'Subunidades', 'Orgão solicitante',
                'Fornecedor Aprovado', 'Nota Fiscal peça', 'Valor',
                'Nota Fiscal serviço', 'Valor', 'Total R$']
      rows = []
      total_parts = 0.0
      total_services = 0.0
      total_geral = 0.0

      @order_services.each do |os|
        approved_proposal = os.getting_order_service_proposal_approved
        provider = approved_proposal&.provider || os.provider
        provider_name = provider&.fantasy_name.presence || provider&.name || '-'

        nf_peca = ''
        nf_servico = ''
        if approved_proposal.present?
          invoices = approved_proposal.order_service_invoices
          nf_peca_rec = invoices.find { |inv| inv.order_service_invoice_type_id == OrderServiceInvoiceType::PECAS_ID }
          nf_servico_rec = invoices.find { |inv| inv.order_service_invoice_type_id == OrderServiceInvoiceType::SERVICOS_ID }
          nf_peca = nf_peca_rec&.number.to_s
          nf_servico = nf_servico_rec&.number.to_s
        end

        sub_unit_name = os.vehicle&.sub_unit&.name || ''
        client_name = os.client&.fantasy_name.presence || os.client&.name || '-'
        modelo = "#{os.vehicle&.brand} #{os.vehicle&.model}".strip

        parts = os.total_parts_value.to_f
        services = os.total_services_value.to_f
        total = os.total_value.to_f

        total_parts += parts
        total_services += services
        total_geral += total

        rows << [
          os.code,
          os.vehicle&.board || '-',
          modelo.truncate(28),
          sub_unit_name.truncate(20),
          client_name.truncate(30),
          provider_name.truncate(30),
          nf_peca,
          CustomHelper.to_currency(parts),
          nf_servico,
          CustomHelper.to_currency(services),
          CustomHelper.to_currency(total)
        ]
      end

      # Linha de totais
      rows << [
        { content: 'Total: R$', colspan: 7, font_style: :bold, align: :right },
        { content: CustomHelper.to_currency(total_parts), font_style: :bold },
        { content: '', font_style: :bold },
        { content: CustomHelper.to_currency(total_services), font_style: :bold },
        { content: CustomHelper.to_currency(total_geral), font_style: :bold }
      ]

      table_data = [header] + rows

      pdf.table(table_data, header: true, width: pdf.bounds.width,
                cell_style: { size: 8, padding: [3, 4, 3, 4] },
                row_colors: ['FFFFFF', 'F5F5F5']) do
        row(0).font_style = :bold
        row(0).background_color = 'E0E0E0'
        row(0).align = :center
        columns(7).align = :right
        columns(9).align = :right
        columns(10).align = :right
      end

      pdf.move_down 15
      pdf.text "Total de OS: #{@order_services.count}", size: 10

      pdf.number_pages 'Página <page> de <total>', at: [pdf.bounds.right - 100, -5], size: 8
    end

    tempfiles_to_cleanup.each { |tmp| tmp.close! rescue nil }

    send_data pdf.render,
              filename: "demonstrativo_faturamento_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  def render_csv
    require 'csv'
    
    csv_data = CSV.generate(headers: true, col_sep: ';', encoding: 'UTF-8') do |csv|
      # Cabeçalho principal
      csv << ['Código', 'Cliente', 'Veículo', 'Placa', 'Tipo OS', 'Status', 'Data Criação', 'Valor Peças', 'Valor Serviços', 'Valor Total']
      
      # Dados de cada OS
      @order_services.each do |os|
        csv << [
          os.code,
          os.client&.social_name.presence || os.client&.fantasy_name.presence || os.client&.name || '-',
          "#{os.vehicle&.brand} #{os.vehicle&.model}".strip.presence || '-',
          os.vehicle&.board || '-',
          os.order_service_type&.name || '-',
          os.order_service_status&.name || '-',
          os.created_at.strftime('%d/%m/%Y'),
          os.total_parts_value || 0,
          os.total_services_value || 0,
          os.total_value || 0
        ]
        
        # Orçamentos/Propostas vinculados à OS
        proposals = os.order_service_proposals.not_complement.includes(:provider, :order_service_proposal_status)
        if proposals.any?
          csv << ['', 'ORÇAMENTOS VINCULADOS:', '', '', '', '', '', '']
          csv << ['', 'Código Orçamento', 'Fornecedor', 'Status', 'Valor', 'Data', '', '']
          proposals.each do |proposal|
            csv << [
              '',
              proposal.code,
              proposal.provider&.fantasy_name || proposal.provider&.name || '-',
              proposal.order_service_proposal_status&.name || '-',
              proposal.total_value || 0,
              proposal.created_at.strftime('%d/%m/%Y'),
              '',
              ''
            ]
          end
          csv << []
        end
      end
      
      # Totalizadores
      csv << []
      csv << ['Total de OSs:', @order_services.count]
      csv << ['Total Peças:', @order_services.sum(&:total_parts_value)]
      csv << ['Total Serviços:', @order_services.sum(&:total_services_value)]
      csv << ['Valor Total:', @order_services.sum(&:total_value)]
    end
    
    send_data csv_data,
              filename: "relatorio_personalizado_#{Date.current.strftime('%Y%m%d')}.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def render_provider_report_pdf
    tempfiles_to_cleanup = []

    client_label = @selected_client&.fantasy_name.presence ||
                   @selected_client&.social_name.presence ||
                   @selected_client&.name || 'Todos os clientes'

    period_label = ''
    if params[:start_date].present? && params[:end_date].present?
      period_label = "#{params[:start_date]} a #{params[:end_date]}"
    elsif params[:start_date].present?
      period_label = "A partir de #{params[:start_date]}"
    elsif params[:end_date].present?
      period_label = "Até #{params[:end_date]}"
    end

    pdf = Prawn::Document.new(page_size: 'A4', page_layout: :landscape) do |pdf|
      pdf.font_size 10

      logo_path = Rails.root.join('app', 'assets', 'images', 'logos', 'logo.png')
      logo_drawn = false
      if File.exist?(logo_path)
        begin
          pdf.image logo_path.to_s, fit: [160, 50], position: :left
          logo_drawn = true
        rescue Prawn::Errors::UnsupportedImageType, Prawn::Errors::UnsupportedImageFormat
          begin
            require 'mini_magick'
            tmp = Tempfile.new(['instasolutions-logo', '.png'])
            tmp.binmode
            image = MiniMagick::Image.open(logo_path.to_s)
            begin; image.interlace 'none'; rescue StandardError; end
            image.format 'png'
            image.write tmp.path
            tempfiles_to_cleanup << tmp
            pdf.image tmp.path, fit: [160, 50], position: :left
            logo_drawn = true
          rescue StandardError
            logo_drawn = false
          end
        end
      end
      pdf.text 'InstaSolutions', size: 16, style: :bold unless logo_drawn

      pdf.move_down 10
      pdf.text 'RELATÓRIO POR ESTABELECIMENTO CREDENCIADO', size: 14, style: :bold, align: :center
      pdf.move_down 5
      pdf.text "Cliente: #{client_label}", size: 11
      pdf.text "Período: #{period_label.presence || 'Todos'}", size: 10
      pdf.text "Data de emissão: #{Date.current.strftime('%d/%m/%Y')}", size: 10
      pdf.move_down 12

      header = ['Estabelecimento', 'Transações', 'Valor Bruto (R$)', 'Valor Líquido (R$)', '% do Contrato']

      rows = @provider_rows.map do |r|
        [
          r[:name].truncate(40),
          r[:transactions].to_s,
          number_to_currency(r[:gross_value], unit: 'R$ ', separator: ',', delimiter: '.', precision: 2),
          number_to_currency(r[:net_value],   unit: 'R$ ', separator: ',', delimiter: '.', precision: 2),
          "#{r[:pct].to_s.gsub('.', ',')}%"
        ]
      end

      rows << [
        { content: 'TOTAL', font_style: :bold },
        { content: @grand_total_transactions.to_s, font_style: :bold },
        { content: number_to_currency(@grand_total_gross, unit: 'R$ ', separator: ',', delimiter: '.', precision: 2), font_style: :bold },
        { content: number_to_currency(@grand_total_net,   unit: 'R$ ', separator: ',', delimiter: '.', precision: 2), font_style: :bold },
        { content: '100%', font_style: :bold }
      ]

      table_data = [header] + rows

      pdf.table(table_data, header: true, width: pdf.bounds.width,
                cell_style: { size: 9, padding: [4, 6, 4, 6] },
                row_colors: ['FFFFFF', 'F5F5F5']) do
        row(0).font_style = :bold
        row(0).background_color = 'E0E0E0'
        row(0).align = :center
        columns(1).align = :center
        columns(2..3).align = :right
        columns(4).align = :center
      end

      pdf.move_down 10
      pdf.text "* Valores bruto e líquido referem-se às propostas aprovadas e subsequentes.", size: 8, color: '888888'
      pdf.text "* Taxa secundária disponível no Portal Financeiro.", size: 8, color: '888888'
      pdf.number_pages 'Página <page> de <total>', at: [pdf.bounds.right - 120, -5], size: 8
    end

    tempfiles_to_cleanup.each { |tmp| tmp.close! rescue nil }

    send_data pdf.render,
              filename: "relatorio_estabelecimentos_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  def render_provider_report_csv
    require 'csv'

    client_label = @selected_client&.fantasy_name.presence ||
                   @selected_client&.social_name.presence ||
                   @selected_client&.name || 'Todos'

    csv_data = CSV.generate(headers: true, col_sep: ';', encoding: 'UTF-8') do |csv|
      csv << ['Relatório por Estabelecimento Credenciado']
      csv << ['Cliente', client_label]
      csv << ['Gerado em', Date.current.strftime('%d/%m/%Y')]
      csv << []
      csv << ['Estabelecimento', 'Qtd. Transações', 'Valor Bruto (R$)', 'Valor Líquido (R$)', '% do Contrato']

      @provider_rows.each do |r|
        csv << [
          r[:name],
          r[:transactions],
          r[:gross_value].to_s.gsub('.', ','),
          r[:net_value].to_s.gsub('.', ','),
          "#{r[:pct].to_s.gsub('.', ',')}%"
        ]
      end

      csv << []
      csv << ['TOTAL', @grand_total_transactions, @grand_total_gross.to_s.gsub('.', ','), @grand_total_net.to_s.gsub('.', ','), '100%']
    end

    send_data csv_data,
              filename: "relatorio_estabelecimentos_#{Date.current.strftime('%Y%m%d')}.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_pdf_report(order_services, selected_client: nil, report_params: {})
    tempfiles_to_cleanup = []

    pdf = Prawn::Document.new(page_size: 'A4', page_layout: :landscape) do |pdf|
      pdf.font_size 10

      logo_path = Rails.root.join('app', 'assets', 'images', 'logos', 'logo.png')

      client_label = selected_client&.social_name.presence ||
        selected_client&.fantasy_name.presence ||
        selected_client&.name

      header_client_text = client_label.presence || 'Todos os clientes'
      header_generated_at = Time.current.strftime('%d/%m/%Y às %H:%M')

      header_top = pdf.cursor
      pdf.bounding_box([0, header_top], width: pdf.bounds.width, height: 60) do
        logo_drawn = false
        if File.exist?(logo_path)
          begin
            pdf.image logo_path.to_s, fit: [160, 50], at: [0, 50]
            logo_drawn = true
          rescue Prawn::Errors::UnsupportedImageType, Prawn::Errors::UnsupportedImageFormat
            begin
              require 'mini_magick'
              tmp = Tempfile.new(['instasolutions-logo', '.png'])
              tmp.binmode
              image = MiniMagick::Image.open(logo_path.to_s)
              begin
                image.interlace 'none'
              rescue StandardError
                # ignore
              end
              image.format 'png'
              image.write tmp.path
              tempfiles_to_cleanup << tmp

              pdf.image tmp.path, fit: [160, 50], at: [0, 50]
              logo_drawn = true
            rescue StandardError
              logo_drawn = false
            end
          end
        end

        pdf.text 'InstaSolutions', size: 16, style: :bold unless logo_drawn

        pdf.bounding_box([175, 60], width: pdf.bounds.width - 175, height: 60) do
          pdf.text 'Relatório Personalizado de Ordens de Serviço', size: 14, style: :bold
          pdf.text "Cliente: #{header_client_text}", size: 10
          if selected_client.present?
            if selected_client.cnpj.present?
              pdf.text "CNPJ: #{selected_client.cnpj}", size: 9
            end

            if selected_client.social_name.present? && selected_client.fantasy_name.present?
              pdf.text "Nome fantasia: #{selected_client.fantasy_name}", size: 9
            end
          end
          pdf.text "Gerado em: #{header_generated_at}", size: 9, color: '666666'
        end
      end

      pdf.move_down 10

      # Filtros aplicados (mostra apenas o que foi preenchido)
      filters_lines = []
      if report_params[:start_date].present? && report_params[:end_date].present?
        filters_lines << "Período: #{report_params[:start_date]} a #{report_params[:end_date]}"
      end

      if report_params[:status_id].present?
        filters_lines << "Status: #{OrderServiceStatus.find_by(id: report_params[:status_id])&.name || '-'}"
      end

      if report_params[:type_id].present?
        filters_lines << "Tipo OS: #{OrderServiceType.find_by(id: report_params[:type_id])&.name || '-'}"
      end

      if report_params[:vehicle_id].present?
        vehicle = Vehicle.find_by(id: report_params[:vehicle_id])
        vehicle_label = if vehicle.present?
          "#{vehicle.brand} #{vehicle.model}".strip.presence || vehicle.board
        end
        filters_lines << "Veículo: #{vehicle_label || '-'}"
      end

      if report_params[:provider_id].present?
        provider = User.find_by(id: report_params[:provider_id])
        filters_lines << "Fornecedor: #{provider&.fantasy_name || provider&.social_name || '-'}"
      end

      if report_params[:cost_center_id].present?
        cost_center = CostCenter.find_by(id: report_params[:cost_center_id])
        filters_lines << "Centro de Custo: #{cost_center&.name || '-'}"
      end

      if report_params[:sub_unit_id].present?
        sub_unit = SubUnit.find_by(id: report_params[:sub_unit_id])
        filters_lines << "Subunidade: #{sub_unit&.name || '-'}"
      end

      if report_params[:commitment_id].present?
        commitment = Commitment.find_by(id: report_params[:commitment_id])
        filters_lines << "Empenho: #{commitment&.commitment_number || '-'}"
      end

      if filters_lines.any?
        pdf.text 'Filtros aplicados:', style: :bold
        filters_lines.each { |line| pdf.text line, size: 9 }
        pdf.move_down 10
      end
      
      # Tabela
      if order_services.any?
        order_services.each do |os|
          # Cabeçalho da OS
          pdf.fill_color '4472C4'
          pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 20
          pdf.fill_color '000000'
          pdf.move_down 5
          client_label = os.client&.social_name.presence || os.client&.fantasy_name.presence || os.client&.name
          pdf.text "OS: #{os.code} | Cliente: #{client_label&.truncate(30) || '-'} | Status: #{os.order_service_status&.name || '-'}", 
                   color: 'FFFFFF', style: :bold, size: 10
          pdf.move_down 10
          
          # Dados da OS
          os_data = [
            ['Veículo', "#{os.vehicle&.brand} #{os.vehicle&.model}".strip.truncate(30) || '-'],
            ['Placa', os.vehicle&.board || '-'],
            ['Tipo OS', os.order_service_type&.name || '-'],
            ['Data Criação', os.created_at.strftime('%d/%m/%Y')],
            ['Valor Peças', CustomHelper.to_currency(os.total_parts_value || 0)],
            ['Valor Serviços', CustomHelper.to_currency(os.total_services_value || 0)],
            ['Valor Total', os.total_value ? CustomHelper.to_currency(os.total_value) : 'R$ 0,00']
          ]
          
          pdf.table(os_data, width: 350, cell_style: { size: 9, padding: 3 }) do
            column(0).font_style = :bold
            column(0).width = 100
          end
          pdf.move_down 8
          
          # Tabela de Orçamentos vinculados à OS
          proposals = os.order_service_proposals.not_complement.includes(:provider, :order_service_proposal_status)
          if proposals.any?
            pdf.text "Orçamentos Vinculados:", style: :bold, size: 9
            pdf.move_down 3
            
            proposal_data = [['Código', 'Fornecedor', 'Status', 'Valor', 'Data']]
            proposals.each do |proposal|
              proposal_data << [
                proposal.code,
                proposal.provider&.fantasy_name&.truncate(25) || proposal.provider&.name&.truncate(25) || '-',
                proposal.order_service_proposal_status&.name&.truncate(20) || '-',
                proposal.total_value ? CustomHelper.to_currency(proposal.total_value) : 'R$ 0,00',
                proposal.created_at.strftime('%d/%m/%Y')
              ]
            end
            
            pdf.table(proposal_data, header: true, width: pdf.bounds.width * 0.8, 
                      cell_style: { size: 8, padding: 3 },
                      row_colors: ['FFFFFF', 'F5F5F5']) do
              row(0).font_style = :bold
              row(0).background_color = 'E0E0E0'
            end
          else
            pdf.text "Nenhum orçamento vinculado.", size: 8, color: '666666'
          end
          
          pdf.move_down 15
          
          # Verificar se precisa de nova página
          pdf.start_new_page if pdf.cursor < 100
        end
        
        # Totalizador final
        pdf.move_down 10
        total_parts = order_services.sum(&:total_parts_value)
        total_services = order_services.sum(&:total_services_value)
        total_value = order_services.sum(&:total_value)
        pdf.text "Total de OSs: #{order_services.count}", style: :bold
        pdf.text "Total Peças: #{CustomHelper.to_currency(total_parts)}", style: :bold
        pdf.text "Total Serviços: #{CustomHelper.to_currency(total_services)}", style: :bold
        pdf.text "Valor Total: #{CustomHelper.to_currency(total_value)}", style: :bold, size: 12
      else
        pdf.text "Nenhuma ordem de serviço encontrada com os filtros aplicados.", align: :center
      end
    end

    tempfiles_to_cleanup.each { |tmp| tmp.close! rescue nil }
    pdf
  end
end
