class CustomReportsController < ApplicationController
  require 'prawn/table' if defined?(Prawn)
  
  before_action :authorize_access

  def index
    # Buscar clientes (Users com perfil de cliente)
    if @current_user.admin?
      @clients = User.client.active.order(:name)
    else
      # Gestor/Adicional vê apenas seu próprio cliente
      @clients = User.client.active.where(id: @current_user.client_id).order(:name)
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
    params[:status_id].present? || params[:type_id].present? ||
    params[:vehicle_id].present?
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
    
    # Filtro por período
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]) rescue nil
      end_date = Date.parse(params[:end_date]) rescue nil
      scope = scope.where(created_at: start_date.beginning_of_day..end_date.end_of_day) if start_date && end_date
    end
    
    # Filtro por status
    if params[:status_id].present?
      scope = scope.where(order_service_status_id: params[:status_id])
    end
    
    # Filtro por tipo de OS
    if params[:type_id].present?
      scope = scope.where(order_service_type_id: params[:type_id])
    end
    
    # Filtro por veículo
    if params[:vehicle_id].present?
      scope = scope.where(vehicle_id: params[:vehicle_id])
    end
    
    scope.order(created_at: :desc)
  end

  def render_pdf
    pdf = generate_pdf_report(@order_services)
    send_data pdf.render,
              filename: "relatorio_personalizado_#{Date.current.strftime('%Y%m%d')}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  def render_csv
    require 'csv'
    
    csv_data = CSV.generate(headers: true, col_sep: ';', encoding: 'UTF-8') do |csv|
      # Cabeçalho principal
      csv << ['Código', 'Cliente', 'Veículo', 'Placa', 'Tipo OS', 'Status', 'Data Criação', 'Valor Total']
      
      # Dados de cada OS
      @order_services.each do |os|
        csv << [
          os.code,
          os.client&.name || '-',
          "#{os.vehicle&.brand} #{os.vehicle&.model}".strip.presence || '-',
          os.vehicle&.board || '-',
          os.order_service_type&.name || '-',
          os.order_service_status&.name || '-',
          os.created_at.strftime('%d/%m/%Y'),
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
      csv << ['Valor Total:', @order_services.sum(&:total_value)]
    end
    
    send_data csv_data,
              filename: "relatorio_personalizado_#{Date.current.strftime('%Y%m%d')}.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_pdf_report(order_services)
    Prawn::Document.new(page_size: 'A4', page_layout: :landscape) do |pdf|
      pdf.font_size 10
      
      # Título
      pdf.text "Relatório Personalizado de Ordens de Serviço", size: 16, style: :bold, align: :center
      pdf.move_down 5
      pdf.text "Gerado em: #{Time.current.strftime('%d/%m/%Y às %H:%M')}", size: 10, align: :center
      pdf.move_down 15
      
      # Filtros aplicados
      if params[:client_id].present? || params[:start_date].present? || params[:status_id].present?
        pdf.text "Filtros aplicados:", style: :bold
        pdf.text "Cliente: #{User.client.find_by(id: params[:client_id])&.name || 'Todos'}"
        pdf.text "Período: #{params[:start_date]} a #{params[:end_date]}" if params[:start_date].present?
        pdf.text "Status: #{OrderServiceStatus.find_by(id: params[:status_id])&.name || 'Todos'}"
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
          pdf.text "OS: #{os.code} | Cliente: #{os.client&.name&.truncate(30) || '-'} | Status: #{os.order_service_status&.name || '-'}", 
                   color: 'FFFFFF', style: :bold, size: 10
          pdf.move_down 10
          
          # Dados da OS
          os_data = [
            ['Veículo', "#{os.vehicle&.brand} #{os.vehicle&.model}".strip.truncate(30) || '-'],
            ['Placa', os.vehicle&.board || '-'],
            ['Tipo OS', os.order_service_type&.name || '-'],
            ['Data Criação', os.created_at.strftime('%d/%m/%Y')],
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
        total_value = order_services.sum(&:total_value)
        pdf.text "Total de OSs: #{order_services.count}", style: :bold
        pdf.text "Valor Total: #{CustomHelper.to_currency(total_value)}", style: :bold
      else
        pdf.text "Nenhuma ordem de serviço encontrada com os filtros aplicados.", align: :center
      end
    end
  end
end
