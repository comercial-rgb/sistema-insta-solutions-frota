class CustomReportsController < ApplicationController
  require 'prawn/table' if defined?(Prawn)
  
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
    
    # Inicializar como vazio se não houver filtros
    if has_filters?
      @order_services = apply_filters(policy_scope(OrderService))
    else
      @order_services = OrderService.none
    end
    
    respond_to do |format|
      format.html
      format.pdf { render_pdf }
      format.csv { render_csv }
    end
  end

  private

  def has_filters?
    params[:client_id].present? || params[:start_date].present? || 
    params[:month].present? || params[:year].present? ||
    params[:status_id].present? || params[:type_id].present? ||
    params[:vehicle_id].present? || params[:provider_id].present? ||
    params[:cost_center_id].present? || params[:sub_unit_id].present?
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
    
    # Filtro por fornecedor (busca OS que têm propostas deste fornecedor)
    if params[:provider_id].present?
      scope = scope.joins(:order_service_proposals)
                   .where(order_service_proposals: { provider_id: params[:provider_id] })
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
