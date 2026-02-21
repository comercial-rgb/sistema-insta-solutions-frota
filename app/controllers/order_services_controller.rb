require 'ostruct'

class OrderServicesController < ApplicationController
  before_action :set_order_service, only: [
    :show, :edit, :update, :destroy,
    :get_order_service, :cancel_order_service, :show_historic,
    :reject_order_service, :unreject_order_service, :back_to_edit_order_service,
    :print_no_values, :request_reevaluation, :finish_reevaluation
  ]
  before_action :load_warranty_panel_data, only: [:edit, :update, :show]

  def index
    authorize OrderService
    defining_data(nil, true, nil, false, nil, params[:order_services_grid], OrderServicesGrid, 'index')
  end

  def show_order_services
    authorize OrderService
    
    # Se status_id = -1, mostrar histórico de rejeições
    if params[:order_service_status_id].to_i == -1
      # Se for fornecedor, mostrar apenas as OSs que ELE rejeitou
      if current_user.provider?
        @order_services = current_user.rejected_order_services
          .where(order_service_status_id: [
            OrderServiceStatus::EM_ABERTO_ID,
            OrderServiceStatus::EM_REAVALIACAO_ID,
            OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID
          ])
          .includes(:client, :vehicle, :order_service_status, :provider_service_type, :manager, :rejected_providers)
          .order(updated_at: :desc)
          .page(params[:page])
          .per(50)
        
        @is_provider_view = true
      else
        # Admin/Gestor: ver todas as OSs rejeitadas
        @order_services = OrderService
          .joins(:rejected_providers)
          .includes(:client, :manager, :rejected_providers)
          .distinct
        
        # Aplicar filtros
        if params[:client_id].present?
          @order_services = @order_services.where(client_id: params[:client_id])
        end
        
        if params[:code].present?
          @order_services = @order_services.where("order_services.code LIKE ?", "%#{params[:code]}%")
        end
        
        @order_services = @order_services
          .order(created_at: :desc)
          .page(params[:page])
          .per(50)
        
        @is_provider_view = false
      end
      
      render 'order_services/rejected_history'
    else
      defining_data(params[:order_service_status_id], nil, nil, false, nil, params[:order_services_grid], OrderServicesGrid, 'show_order_services')
    end
  end

  def show_invoices
    authorize OrderService
    # Para Faturas, não filtrar por status atual - usar histórico de aprovações
    defining_data(nil, true, nil, true, true, params[:order_services_invoice_grid], OrderServicesInvoiceGrid, 'show_invoices')
  end

  def rejected_history
    authorize OrderService
    
    # Buscar apenas OSs que possuem fornecedores rejeitados
    @order_services = OrderService
      .joins(:rejected_providers)
      .includes(:client, :manager, :rejected_providers)
      .distinct
    
    # Aplicar filtros
    if params[:client_id].present?
      @order_services = @order_services.where(client_id: params[:client_id])
    end
    
    if params[:code].present?
      @order_services = @order_services.where("order_services.code LIKE ?", "%#{params[:code]}%")
    end
    
    @order_services = @order_services
      .order(created_at: :desc)
      .page(params[:page])
      .per(50)
    
    render 'order_services/rejected_history'
  end

  def dashboard
    authorize OrderService
    defining_data(nil, true, nil, false, nil, params[:order_services_grid], OrderServicesGrid, 'dashboard')

    if current_user.manager? || current_user.additional?
      client_id = current_user.client_id
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = current_user.associated_sub_units.map(&:id)
      # Obter todos os cost_centers acessíveis pelo usuário
      cost_centers = CostCenter.where(id: cost_center_ids)
    elsif current_user.admin?
      # Para admin, verificar se há filtros aplicados
      grid_params = params[:order_services_grid] || {}
      
      # Se há filtro de client_id, usar os cost_centers desse cliente
      if grid_params[:client_id].present?
        client = User.find_by(id: grid_params[:client_id])
        cost_centers = client&.client_cost_centers || CostCenter.none
        cost_center_ids = cost_centers.map(&:id)
        sub_unit_ids = SubUnit.where(cost_center_id: cost_center_ids).pluck(:id)
      # Se há filtro de cost_center_id
      elsif grid_params[:cost_center_id].present?
        cost_centers = CostCenter.where(id: grid_params[:cost_center_id])
        cost_center_ids = [grid_params[:cost_center_id].to_i]
        sub_unit_ids = SubUnit.where(cost_center_id: cost_center_ids).pluck(:id)
      # Se há filtro de sub_unit_id
      elsif grid_params[:sub_unit_id].present?
        sub_unit = SubUnit.find_by(id: grid_params[:sub_unit_id])
        sub_unit_ids = [sub_unit&.id].compact
        cost_center_ids = [sub_unit&.cost_center_id].compact
        cost_centers = CostCenter.where(id: cost_center_ids)
      else
        # Sem filtros: buscar cost_centers que têm OSs aprovadas/autorizadas para otimizar
        required_statuses = OrderServiceStatus::REQUIRED_ORDER_SERVICE_STATUSES
        cost_center_ids_with_os = Vehicle.joins(:order_services)
          .where(order_services: { order_service_status_id: required_statuses })
          .where.not(cost_center_id: nil)
          .distinct
          .pluck(:cost_center_id)
        
        cost_centers = CostCenter.where(id: cost_center_ids_with_os)
        cost_center_ids = cost_center_ids_with_os
        sub_unit_ids = SubUnit.where(cost_center_id: cost_center_ids).pluck(:id)
      end
    else
      # Para client, usar seu próprio centro de custo/sub-unidade
      cost_center_ids = []
      sub_unit_ids = []
      cost_centers = []
    end

    @echart_values = {
      builderJson: OrderService.generate_dashboard_to_charts(@order_services_to_export.assets, cost_centers, cost_center_ids, sub_unit_ids),
      downloadJson: OrderService.getting_vehicles_to_charts(@order_services_to_export.assets, cost_centers, cost_center_ids, sub_unit_ids),
      themeJson: OrderService.getting_cost_center_values(@order_services_to_export.assets, cost_centers, cost_center_ids, sub_unit_ids),
      typesJson: OrderService.getting_values_by_type(@order_services_to_export.assets, cost_centers, cost_center_ids, sub_unit_ids)
    }
  end

  def show
    authorize @order_service
    @order_service.reload # Força reload para evitar cache
    
    # Busca APENAS propostas que NÃO são complementos (complementos serão mostrados dentro da proposta pai)
    proposals_base = @order_service.order_service_proposals
      .reload
      .where.not(order_service_proposal_status_id: OrderServiceProposalStatus::EM_CADASTRO_ID)
      .where(is_complement: [false, nil])  # Excluir complementos da lista principal
      .includes(:provider, :order_service_proposal_status, :order_service_proposal_items)
    
    # 🔒 CORREÇÃO: Para fornecedores, filtrar apenas suas próprias propostas
    # Isso evita que um fornecedor veja propostas de outros fornecedores quando a OS
    # de Diagnóstico é enviada para cotação (outros fornecedores)
    if @current_user.provider?
      @order_service_proposals = proposals_base.where(provider_id: @current_user.id).reorder(total_value: :asc)
    else
      # Para admin/manager/additional, mostra todas as propostas
      @order_service_proposals = proposals_base.reorder(total_value: :asc)
    end
    
    # Debug temporário - pode remover depois
    Rails.logger.debug "=== DEBUG PROPOSTAS ==="
    @order_service_proposals.each do |p|
      Rails.logger.debug "Proposta #{p.code} - Status ID: #{p.order_service_proposal_status_id} - Status Nome: #{p.order_service_proposal_status&.name}"
      # Verificar se tem complementos
      complements_count = p.complement_proposals.count
      Rails.logger.debug "  -> Tem #{complements_count} complemento(s)"
    end
  end

  def print_no_values
    authorize @order_service, :print_no_values?

    render layout: 'print_no_values'
  end

  def defining_data(order_service_status_id, show_order_service_status, order_service_status_ids, filter_audit, period_filter, order_services_grid, order_services_grid_class, method)
    # Tratar pseudo-status "aguardando_complemento"
    if order_service_status_id == 'aguardando_complemento'
      @order_service_status = OpenStruct.new(
        id: 'aguardando_complemento',
        name: 'Aguardando Aprovação de Complemento'
      )
    elsif !order_service_status_id.nil? && order_service_status_id != OrderServiceStatus::TEMP_REJEITADA_ID
      @order_service_status = OrderServiceStatus.where(id: order_service_status_id).first
    end

    current_month = nil
    filter_by_status_date = false
    status_date_range = nil
    
    if order_services_grid.nil? || order_services_grid.blank?
      @order_services = order_services_grid_class.new(:current_user => @current_user)
      @order_services_to_export = order_services_grid_class.new(:current_user => @current_user)
      month = Date.today.month.to_i
      year = Date.today.year.to_i
      current_month = (Date.new(year, month, 1)).beginning_of_month..Date.new(year, month, 1).end_of_month
    else
      @order_services = order_services_grid_class.new(order_services_grid.merge(current_user: @current_user))
      @order_services_to_export = order_services_grid_class.new(order_services_grid.merge(current_user: @current_user))
      if order_services_grid[:month] && order_services_grid[:year]
        month = order_services_grid[:month].to_i
        year = order_services_grid[:year].to_i
        current_month = (Date.new(year, month, 1)).beginning_of_month..Date.new(year, month, 1).end_of_month
      end
      
      # Verifica se há filtro de "Última atualização" e aba específica de status
      if order_services_grid[:updated_at].present? && order_service_status_id.present? && 
         order_service_status_id != OrderServiceStatus::TEMP_REJEITADA_ID
        filter_by_status_date = true
        start_date = order_services_grid[:updated_at][0]
        end_date = order_services_grid[:updated_at][1]
        if start_date.present? && end_date.present?
          status_date_range = DateTime.parse("#{start_date} 00:00:00")..DateTime.parse("#{end_date} 23:59:59")
        elsif start_date.present?
          status_date_range = DateTime.parse("#{start_date} 00:00:00")..DateTime.now.end_of_day
        elsif end_date.present?
          status_date_range = DateTime.new(2000,1,1)..DateTime.parse("#{end_date} 23:59:59")
        end
      end
    end

    # @order_services_without_filter precisa ter mês/ano para popular os filtros corretamente
    if order_services_grid.nil? || order_services_grid.blank?
      @order_services_without_filter = order_services_grid_class.new(:current_user => @current_user)
    else
      # Manter apenas filtros de período (mês/ano) para popular os dropdowns
      grid_params_for_filter = { current_user: @current_user }
      grid_params_for_filter[:month] = order_services_grid[:month] if order_services_grid[:month]
      grid_params_for_filter[:year] = order_services_grid[:year] if order_services_grid[:year]
      @order_services_without_filter = order_services_grid_class.new(grid_params_for_filter)
    end

    if @current_user.manager? || @current_user.additional?
      client_id = @current_user.client_id
      cost_center_ids = @current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = @current_user.associated_sub_units.map(&:id)
    end

    if @current_user.admin?
      # Tratamento especial para pseudo-status "aguardando_complemento"
      if order_service_status_id == 'aguardando_complemento'
        @order_services.scope {|scope| scope
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct
          .page(params[:page]) }

        @order_services_to_export.scope {|scope| scope
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct }

        @order_services_without_filter.scope {|scope| scope
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct }
      elsif order_service_status_id.to_i == OrderServiceStatus::TEMP_REJEITADA_ID
        # ✅ Status REJEIÇÕES: mostrar APENAS OS que possuem fornecedor(es) rejeitado(s)
        @order_services.scope {|scope| scope
          .joins(:rejected_providers)
          .distinct
          .page(params[:page]) }

        @order_services_to_export
          .scope {|scope| scope
            .joins(:rejected_providers)
            .distinct }

        @order_services_without_filter
          .scope {|scope| scope
            .joins(:rejected_providers)
            .distinct }
      elsif (order_service_status_id.nil? && method != "show_invoices" && method != "index")
        # Mantém comportamento atual quando não há status informado (evita impacto em outras telas)
        @order_services.scope {|scope| scope.left_joins(:rejected_providers)
        .approved_in_current_month(filter_audit, current_month)
        .page(params[:page]) }

        @order_services_to_export
        .scope {|scope| scope.left_joins(:rejected_providers)
        .approved_in_current_month(filter_audit, current_month)}

        @order_services_without_filter
        .scope {|scope| scope.left_joins(:rejected_providers)
        .approved_in_current_month(filter_audit, current_month)}
      else
        if method == "show_invoices" && !params[:order_services_invoice_grid].nil?
          client_id = params[:order_services_invoice_grid][:client_id].presence
        elsif method == "index" && !params[:order_services_grid].nil?
          client_id = params[:order_services_grid][:client_id].presence
        end
        
        # Aba FATURAS: sempre usa histórico para pegar OSs autorizadas no período
        # permite múltiplos status (Autorizada, Nota Fiscal, Aguardando Pagamento, Paga)
        if method == "show_invoices" && filter_audit && current_month
          @order_services.scope {|scope| scope
          .by_client_id(client_id)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids)
          .page(params[:page]) }

          @order_services_to_export.scope {|scope| scope
          .by_client_id(client_id)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids) }

          @order_services_without_filter.scope {|scope| scope
          .by_client_id(client_id)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids) }
        # Abas normais com filtro de data: usa reached_status_in_period
        elsif filter_by_status_date && status_date_range.present?
          # Se há múltiplos status permitidos, permite OSs em qualquer um desses status
          # que passaram pelo status da aba no período
          if order_service_status_ids.present?
            @order_services.scope {|scope| scope
            .by_client_id(client_id)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            )
            .page(params[:page]) }

            @order_services_to_export.scope {|scope| scope
            .by_client_id(client_id)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }

            @order_services_without_filter.scope {|scope| scope
            .by_client_id(client_id)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }
          else
            # Aba de status único: mostra APENAS OSs que ESTÃO naquele status E entraram nele no período
            @order_services.scope {|scope| scope
            .by_client_id(client_id)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            )
            .page(params[:page]) }

            @order_services_to_export.scope {|scope| scope
            .by_client_id(client_id)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }

            @order_services_without_filter.scope {|scope| scope
            .by_client_id(client_id)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }
          end
        else
          # Comportamento padrão: filtra por status atual
          @order_services.scope {|scope|
          scoped = scope
            .by_client_id(client_id)
            .approved_in_current_month(filter_audit, current_month)
            .by_order_service_statuses_id(order_service_status_ids)
            .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped.page(params[:page]) }

          @order_services_to_export.scope {|scope|
          scoped = scope
            .by_client_id(client_id)
            .approved_in_current_month(filter_audit, current_month)
            .by_order_service_statuses_id(order_service_status_ids)
            .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped }

          @order_services_without_filter.scope {|scope|
          scoped = scope
            .by_client_id(client_id)
            .approved_in_current_month(filter_audit, current_month)
            .by_order_service_statuses_id(order_service_status_ids)
            .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped }
        end
      end
    elsif @current_user.manager? || @current_user.additional?
      # Tratamento especial para pseudo-status "aguardando_complemento"
      if order_service_status_id == 'aguardando_complemento'
        @order_services.scope {|scope| scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct
          .page(params[:page]) }

        @order_services_to_export.scope {|scope| scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct }

        @order_services_without_filter.scope {|scope| scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
          .joins(:order_service_proposals)
          .where(order_service_proposals: { 
            is_complement: true,
            order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
          })
          .distinct }
      elsif order_service_status_id.to_i == OrderServiceStatus::TEMP_REJEITADA_ID
        # ✅ Status REJEIÇÕES: mostrar APENAS OS que possuem fornecedor(es) rejeitado(s)
        @order_services.scope {|scope| scope
          .joins(:rejected_providers)
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .distinct
          .page(params[:page]) }

        @order_services_to_export.scope {|scope| scope
          .joins(:rejected_providers)
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .distinct }

        @order_services_without_filter.scope {|scope| scope
          .joins(:rejected_providers)
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .distinct }
      elsif order_service_status_id.nil?
        # Mantém comportamento atual quando não há status informado (evita impacto em outras telas)
        @order_services.scope {|scope| scope.left_joins(:rejected_providers)
        .by_client_id(client_id)
        .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
        .approved_in_current_month(filter_audit, current_month).page(params[:page]) }

        @order_services_to_export.scope {|scope| scope.left_joins(:rejected_providers)
        .by_client_id(client_id)
        .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
        .approved_in_current_month(filter_audit, current_month)}

        @order_services_without_filter.scope {|scope| scope.left_joins(:rejected_providers)
        .by_client_id(client_id)
        .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
        .approved_in_current_month(filter_audit, current_month)}
      else
        # Aba FATURAS: sempre usa histórico para pegar OSs autorizadas no período
        if method == "show_invoices" && filter_audit && current_month
          @order_services.scope {|scope| scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids)
          .page(params[:page]) }

          @order_services_to_export.scope {|scope| scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids) }

          @order_services_without_filter.scope {|scope| scope
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids) }
        # Abas normais com filtro de data
        elsif filter_by_status_date && status_date_range.present?
          # Se há múltiplos status permitidos, permite OSs em qualquer um desses status
          # que passaram pelo status da aba no período
          if order_service_status_ids.present?
            @order_services.scope {|scope| scope
            .by_client_id(client_id)
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            )
            .page(params[:page]) }

            @order_services_to_export.scope {|scope| scope
            .by_client_id(client_id)
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }

            @order_services_without_filter.scope {|scope| scope
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .in_statuses_reached_in_period(order_service_status_ids, order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }
          else
            # Aba de status único: mostra APENAS OSs que ESTÃO naquele status E entraram nele no período
            @order_services.scope {|scope| scope
            .by_client_id(client_id)
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            )
            .page(params[:page]) }

            @order_services_to_export.scope {|scope| scope
            .by_client_id(client_id)
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }

            @order_services_without_filter.scope {|scope| scope
            .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
            .reached_status_in_period(order_service_status_id, status_date_range)
            .where.not(
              id: (order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID ? OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id) : [])
            ) }
          end
        else
          # Comportamento padrão
          @order_services.scope {|scope|
          scoped = scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids)
          .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped.page(params[:page]) }

          @order_services_to_export.scope {|scope|
          scoped = scope
          .by_client_id(client_id)
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids)
          .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped }

          @order_services_without_filter.scope {|scope|
          scoped = scope
          .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
          .approved_in_current_month(filter_audit, current_month)
          .by_order_service_statuses_id(order_service_status_ids)
          .by_order_service_status_id(order_service_status_id)

          if order_service_status_id.to_i == OrderServiceStatus::APROVADA_ID
            scoped = scoped.where.not(
              id: OrderService
                .by_client_id(client_id)
                .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                .where(order_service_status_id: OrderServiceStatus::APROVADA_ID)
                .joins(:order_service_proposals)
                .where(order_service_proposals: {
                  is_complement: true,
                  order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_APROVACAO_COMPLEMENTO_ID
                })
                .select(:id)
            )
          end

          scoped }
        end
      end
    elsif @current_user.provider?
      provider_state_id = -1
      if !@current_user.address.nil? && !@current_user.address.state.nil?
        provider_state_id = @current_user.address.state_id
      end
      provider_service_types_ids = @current_user.provider_service_types.map(&:id)

      if !order_service_status_id.nil? && order_service_status_id.to_i == OrderServiceStatus::EM_ABERTO_ID
          rejected_ids = @current_user.rejected_order_services.map(&:id)
          statuses_to_filter = [OrderServiceStatus::EM_ABERTO_ID, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID]
          
          # 🎯 LÓGICA CORRIGIDA:
          # Mostra OS apenas se o fornecedor NÃO tem proposta ativa (não cancelada/reprovada)
          # Isso vale tanto para:
          # - Diagnóstico direcionado (provider_id = fornecedor)
          # - Cotação/Requisição (provider_id IS NULL)
          # - Diagnóstico enviado para cotação (provider_id foi limpo, mas fornecedor original já tem proposta)
          
          @order_services = @order_services.scope do |scope|
            scope
              .where.not(id: [rejected_ids])
              .by_order_service_statuses_id(statuses_to_filter)
              .where(
                "(
                  (order_services.provider_id = ? OR order_services.provider_id IS NULL)
                  AND order_services.client_id IN (SELECT user_id FROM states_users WHERE state_id = ?)
                  AND order_services.provider_service_type_id IN (?)
                  AND NOT EXISTS (
                    SELECT 1 FROM order_service_proposals osp 
                    WHERE osp.order_service_id = order_services.id 
                    AND osp.provider_id = ? 
                    AND osp.order_service_proposal_status_id NOT IN (?)
                  )
                  AND (
                    order_services.directed_to_specific_providers = FALSE
                    OR order_services.directed_to_specific_providers IS NULL
                    OR EXISTS (
                      SELECT 1 FROM order_service_directed_providers osdp
                      WHERE osdp.order_service_id = order_services.id
                      AND osdp.provider_id = ?
                    )
                  )
                )",
                @current_user.id,
                provider_state_id,
                provider_service_types_ids,
                @current_user.id,
                [
                  OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
                  OrderServiceProposalStatus::CANCELADA_ID
                ],
                @current_user.id
              )
              .distinct
              .page(params[:page])
          end
          
          @order_services_to_export.scope do |scope|
            scope
              .where.not(id: [rejected_ids])
              .by_order_service_statuses_id(statuses_to_filter)
              .where(
                "(
                  (order_services.provider_id = ? OR order_services.provider_id IS NULL)
                  AND order_services.client_id IN (SELECT user_id FROM states_users WHERE state_id = ?)
                  AND order_services.provider_service_type_id IN (?)
                  AND NOT EXISTS (
                    SELECT 1 FROM order_service_proposals osp 
                    WHERE osp.order_service_id = order_services.id 
                    AND osp.provider_id = ? 
                    AND osp.order_service_proposal_status_id NOT IN (?)
                  )
                  AND (
                    order_services.directed_to_specific_providers = FALSE
                    OR order_services.directed_to_specific_providers IS NULL
                    OR EXISTS (
                      SELECT 1 FROM order_service_directed_providers osdp
                      WHERE osdp.order_service_id = order_services.id
                      AND osdp.provider_id = ?
                    )
                  )
                )",
                @current_user.id,
                provider_state_id,
                provider_service_types_ids,
                @current_user.id,
                [
                  OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
                  OrderServiceProposalStatus::CANCELADA_ID
                ],
                @current_user.id
              )
              .distinct
          end
          
          @order_services_without_filter.scope do |scope|
            scope
              .where.not(id: [rejected_ids])
              .by_order_service_statuses_id(statuses_to_filter)
              .where(
                "(
                  (order_services.provider_id = ? OR order_services.provider_id IS NULL)
                  AND order_services.client_id IN (SELECT user_id FROM states_users WHERE state_id = ?)
                  AND order_services.provider_service_type_id IN (?)
                  AND NOT EXISTS (
                    SELECT 1 FROM order_service_proposals osp 
                    WHERE osp.order_service_id = order_services.id 
                    AND osp.provider_id = ? 
                    AND osp.order_service_proposal_status_id NOT IN (?)
                  )
                  AND (
                    order_services.directed_to_specific_providers = FALSE
                    OR order_services.directed_to_specific_providers IS NULL
                    OR EXISTS (
                      SELECT 1 FROM order_service_directed_providers osdp
                      WHERE osdp.order_service_id = order_services.id
                      AND osdp.provider_id = ?
                    )
                  )
                )",
                @current_user.id,
                provider_state_id,
                provider_service_types_ids,
                @current_user.id,
                [
                  OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID,
                  OrderServiceProposalStatus::CANCELADA_ID
                ],
                @current_user.id
              )
              .distinct
          end
      elsif !order_service_status_id.nil? && order_service_status_id.to_i == OrderServiceStatus::TEMP_REJEITADA_ID
        rejected_ids = @current_user.rejected_order_services.map(&:id)
        @order_services.scope {
          |scope| scope
          .where(id: [rejected_ids])
          .by_state_id(provider_state_id)
          .by_provider_service_types_id(provider_service_types_ids)
          .visible_by_provider(@current_user.id)
          .page(params[:page])
        }
        @order_services_to_export.scope {
          |scope| scope
          .where(id: [rejected_ids])
          .by_state_id(provider_state_id)
          .by_provider_service_types_id(provider_service_types_ids)
          .visible_by_provider(@current_user.id)
        }
        @order_services_without_filter.scope {
          |scope| scope
          .where(id: [rejected_ids])
          .by_state_id(provider_state_id)
          .by_provider_service_types_id(provider_service_types_ids)
          .visible_by_provider(@current_user.id)
        }
      # Em reavaliação - fornecedor vê apenas OS onde ele tem proposta
      elsif !order_service_status_id.nil? && order_service_status_id.to_i == OrderServiceStatus::EM_REAVALIACAO_ID
        @order_services.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::EM_REAVALIACAO_ID)
          .with_user_relation(@current_user.id)
          .page(params[:page])
        }
        @order_services_to_export.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::EM_REAVALIACAO_ID)
          .with_user_relation(@current_user.id)
        }
        @order_services_without_filter.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::EM_REAVALIACAO_ID)
          .with_user_relation(@current_user.id)
        }
      # Cancelada - fornecedor vê apenas OS onde ele tinha proposta
      elsif !order_service_status_id.nil? && order_service_status_id.to_i == OrderServiceStatus::CANCELADA_ID
        @order_services.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::CANCELADA_ID)
          .with_user_relation(@current_user.id)
          .page(params[:page])
        }
        @order_services_to_export.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::CANCELADA_ID)
          .with_user_relation(@current_user.id)
        }
        @order_services_without_filter.scope {
          |scope| scope
          .by_order_service_status_id(OrderServiceStatus::CANCELADA_ID)
          .with_user_relation(@current_user.id)
        }
      else
        if method == 'index'
          @order_services.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .with_user_relation(@current_user.id)
            .page(params[:page])
          }
          @order_services_to_export.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .with_user_relation(@current_user.id)
          }
          @order_services_without_filter.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .with_user_relation(@current_user.id)
          }
        else
          @order_services.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .by_state_id(provider_state_id)
            .by_provider_service_types_id(provider_service_types_ids)
            .visible_by_provider(@current_user.id)
            .page(params[:page])
          }
          @order_services_to_export.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .by_state_id(provider_state_id)
            .by_provider_service_types_id(provider_service_types_ids)
            .visible_by_provider(@current_user.id)
          }
          @order_services_without_filter.scope {
            |scope| scope
            .by_order_service_status_id(order_service_status_id)
            .by_state_id(provider_state_id)
            .by_provider_service_types_id(provider_service_types_ids)
            .visible_by_provider(@current_user.id)
          }
        end
      end
    end

    if !period_filter.nil?
      [@order_services, @order_services_to_export, @order_services_without_filter].each do |grid|
        grid.period_filter = period_filter
      end
    end

    clients = @order_services_without_filter.assets.map(&:client).map {|c| [c.fantasy_name, c.id] }.uniq

    managers = @order_services_without_filter.assets.map(&:manager).map {|c| [c.get_name, c.id] }.uniq

    current_cost_center_ids = @order_services_without_filter.assets.map{|item| item.vehicle.cost_center_id}.uniq.flatten
    if @current_user.manager? || @current_user.additional?
      current_cost_center_ids = cost_center_ids
    end
    cost_centers = CostCenter.where(id: [current_cost_center_ids]).joins(:order_services).distinct.order(:name).map {|c| [c.name, c.id] }.uniq

    vehicles = @order_services_without_filter.assets.map(&:vehicle).map {|c| [c.get_text_name, c.id] }.uniq

    commitments = @order_services_without_filter.assets.map(&:commitment).select{|item| !item.nil?}.map {|c| [c.get_text_name, c.id] }.uniq

    sub_units = @order_services_without_filter.assets.map(&:vehicle).select{|item| !item.nil? }.map{|item| item.sub_unit}.compact.uniq.map {|c| [c.get_text_name, c.id] }.uniq

    provider_service_types = @order_services_without_filter.assets.map(&:provider_service_type).map {|c| [c.get_text_name, c.id] }.uniq

    order_service_types = @order_services_without_filter.assets.map(&:order_service_type).map {|c| [c.get_text_name, c.id] }.uniq

    order_service_ids = @order_services_without_filter.assets.map(&:id).uniq
    order_service_proposals = OrderServiceProposal.by_order_services_id(order_service_ids)

    provider_ids = order_service_proposals.map(&:provider_id)
    provider_ids.concat(@order_services_without_filter.assets.map(&:provider_id))
    providers = User.provider.name_ordered.where(id: [provider_ids]).order(:name).map {|c| [c.get_name, c.id] }.uniq

    # Atribuir dados para todos os grids (incluindo filtros)
    [@order_services, @order_services_to_export, @order_services_without_filter].each do |grid|
      grid.clients = clients
      grid.managers = managers
      grid.cost_centers = cost_centers
      grid.vehicles = vehicles
      grid.provider_service_types = provider_service_types
      grid.order_service_types = order_service_types
      grid.providers = providers
      grid.commitments = commitments
      grid.sub_units = sub_units
      grid.method = method
    end

    if !order_service_status_id.nil?
      @order_services.current_order_service_status_id = order_service_status_id.to_i
      @order_services_to_export.current_order_service_status_id = order_service_status_id.to_i
    end

    if !show_order_service_status.nil?
      @order_services.show_order_service_status = show_order_service_status
      @order_services_to_export.show_order_service_status = show_order_service_status
    end

    respond_to do |format|
      format.html
      format.text do
        current_client = User.client.where(id: clients.first[1]).first
        file_path = Utils::OrderServices::GenerateInvoiceDocxService.new(@order_services_to_export.assets, current_client, current_month).call
        send_file file_path,
        filename: 'fatura_template.docx',
        :content_type => "application/docx",
        type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        :disposition => 'inline'
      end
      format.csv do
        send_data @order_services_to_export.to_csv(col_sep: ";").encode("ISO-8859-1"),
        type: "text/csv",
        disposition: 'inline',
        filename: OrderService.model_name.human(count: 2)+" - #{Time.now.to_s}.csv"
      end
      format.pdf do
        pdf = Utils::DatagridPdfExporter.new(@order_services_to_export, title: OrderService.model_name.human(count: 2)).call
        send_data pdf,
          type: 'application/pdf',
          disposition: 'inline',
          filename: OrderService.model_name.human(count: 2)+" - #{Time.now.to_s}.pdf"
      end
    end
  end

  def new
    authorize OrderService
    @order_service = OrderService.new(order_service_status_id: OrderServiceStatus::EM_CADASTRO_ID)
    build_initial_relations
  end

  def generate_data_order_service
    # Método mantido para compatibilidade, mas não é mais usado
    @order_service = FactoryBot.build(:order_service, order_service_status_id: OrderServiceStatus::EM_CADASTRO_ID)
  end

  def edit
    authorize @order_service
    if @current_user.provider?
      if @order_service.parts_services_added && !@order_service.data_inserted_by_provider
        redirect_to new_order_service_proposal_path(order_service_id: @order_service.id) and return
      end
    end
    build_initial_relations
  end

  def create
    authorize OrderService
    @order_service = OrderService.new(order_service_params.except(:parts_photos))
    if @current_user.client?
      @order_service.client_id = @current_user.id
    elsif @current_user.manager?
      @order_service.client_id = @current_user.client_id
    end
    if !params[:save_and_submit].nil?
      @order_service.order_service_status_id = OrderServiceStatus::EM_ABERTO_ID
    else
      @order_service.order_service_status_id = OrderServiceStatus::EM_CADASTRO_ID
    end
    @order_service.invoice_part_ir = 1.2
    @order_service.invoice_part_pis = 0.65
    @order_service.invoice_part_cofins = 3
    @order_service.invoice_part_csll = 1
    @order_service.invoice_service_ir = 4.8
    @order_service.invoice_service_pis = 0.65
    @order_service.invoice_service_cofins = 3
    @order_service.invoice_service_csll = 1
    
    if @order_service.save
      if @order_service.order_service_type_id == OrderServiceType::COTACOES_ID
        @order_service.update_columns(provider_id: nil)
      end
      # Processar fornecedores direcionados
      handle_directed_providers
      @order_service.audit_creation(@current_user)
      save_files
      flash[:success] = t('flash.create')
      redirect_to show_order_services_path(order_service_status_id: @order_service.order_service_status_id)
    else
      flash[:error] = @order_service.errors.full_messages.join('<br>')
      build_initial_relations
      render :new
    end
  end

  def update
    authorize @order_service
    
    # 📊 Log para debug - part_service_order_services antes do update
    Rails.logger.info "🔍 [OS UPDATE DEBUG] Params recebidos para part_service_order_services:"
    if params[:order_service][:part_service_order_services_attributes].present?
      params[:order_service][:part_service_order_services_attributes].each do |key, attrs|
        Rails.logger.info "  [#{key}] id=#{attrs[:id]}, service_id=#{attrs[:service_id]}, _destroy=#{attrs[:_destroy]}"
      end
    end
    Rails.logger.info "🔍 [OS UPDATE DEBUG] Part Services antes do update: #{@order_service.part_service_order_services.count}"
    
    # Verificar quantos estão marcados para destruição
    destroy_count = 0
    if params[:order_service][:part_service_order_services_attributes].present?
      destroy_count = params[:order_service][:part_service_order_services_attributes].values.count { |v| v[:_destroy] == "true" || v[:_destroy] == true || v[:_destroy] == "1" }
    end
    Rails.logger.info "🔍 [OS UPDATE DEBUG] Itens marcados para destruição: #{destroy_count}"
    
    # Verificar se houve alteração nas peças/serviços (para Cotações e Requisições)
    parts_services_changed = false
    if [OrderServiceType::COTACOES_ID, OrderServiceType::REQUISICAO_ID].include?(@order_service.order_service_type_id)
      old_parts_services = @order_service.part_service_order_services.pluck(:service_id, :quantity).sort
      new_params = params[:order_service][:part_service_order_services_attributes]
      if new_params.present?
        new_parts_services = new_params.values.reject { |v| v[:_destroy] == "1" || v[:_destroy] == true || v[:_destroy] == "true" }
                                        .map { |v| [v[:service_id].to_i, v[:quantity].to_i] }.sort
        parts_services_changed = old_parts_services != new_parts_services
      end
    end
    
    # CORREÇÃO: Verificar se update foi bem-sucedido (respeita validações)
    update_success = @order_service.update(order_service_params)
    
    # 📊 Log após update
    Rails.logger.info "✅ [OS UPDATE DEBUG] Update success: #{update_success}"
    Rails.logger.info "✅ [OS UPDATE DEBUG] Part Services após update: #{@order_service.part_service_order_services.reload.count}"
    @order_service.part_service_order_services.each do |ps|
      Rails.logger.info "  - id=#{ps.id}, service_id=#{ps.service_id}, category=#{ps.service&.category_id}"
    end
    
    if update_success
      # Se peças/serviços foram alterados em Cotações/Requisições, cancelar propostas existentes
      if parts_services_changed && @order_service.has_active_proposals?
        @order_service.cancel_all_proposals!(@current_user, "Peças/serviços da OS foram alterados pelo usuário")
        flash[:warning] = "As propostas existentes foram canceladas devido à alteração de peças/serviços. Novas propostas serão necessárias."
      end
      
      if !params[:save_and_submit].nil?
        @order_service.order_service_status_id = OrderServiceStatus::EM_ABERTO_ID
        OrderService.generate_historic(@order_service, @current_user, OrderServiceStatus::EM_CADASTRO_ID, OrderServiceStatus::EM_ABERTO_ID)
      elsif !params[:save_and_insert_values].nil?
        @order_service.parts_services_added = true
      elsif !params[:save_and_submit_to_approve].nil?
        @order_service.data_inserted_by_provider = true
      elsif !params[:release_to_quotation].nil?
        @order_service.release_quotation = true
      end
      @order_service.save!
      # Processar fornecedores direcionados
      handle_directed_providers
      save_files
      if !params[:save_and_submit].nil?
        OrderService.reprove_all_by_edition(@order_service, @current_user)
      end
      if !params[:save_and_insert_values].nil?
        flash[:success] = OrderService.human_attribute_name(:parts_services_added_success)
        redirect_to new_order_service_proposal_path(order_service_id: @order_service.id)
      else
        flash[:success] = t('flash.update')
        redirect_to show_order_services_path(order_service_status_id: @order_service.order_service_status_id)
      end
    else
      flash[:error] = @order_service.errors.full_messages.join('<br>')
      build_initial_relations
      render :edit
    end
  end

  def save_files
    if order_service_params[:files].present?
      order_service_params[:files].each do |picture|
        @order_service.attachments.create(attachment: picture)
      end
    end

    vehicle_photos = params.dig(:order_service, :vehicle_photos) || {}
    vehicle_photos.each do |category_key, file|
      next if file.blank?
      @order_service.attachments.create(attachment: file, category: category_key.to_s)
    end

    parts_photos = params.dig(:order_service, :parts_photos) || []
    Array(parts_photos).each do |file|
      next if file.blank?
      @order_service.attachments.create(attachment: file, category: Attachment::CATEGORIES[:pecas_servicos])
    end
  end

  def destroy
    authorize @order_service
    if @order_service.destroy
      flash[:success] = t('flash.destroy')
    else
      flash[:error] = @order_service.errors.full_messages.join('<br>')
    end
    redirect_back(fallback_location: :back)
  end

  def build_initial_relations
    # if @order_service.relations.select{ |item| item[:id].nil? }.length == 0
    #  @order_service.relations.build
    # end
    # @order_service.build_relation if @order_service.relation.nil?
  end

  def get_order_service
    data = {
      result: @order_service
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def cancel_order_service
    authorize @order_service
    if !params[:cancel_justification].nil? && !params[:cancel_justification].blank?
      @order_service.order_service_proposals.select{|item| item.order_service_proposal_status_id != OrderServiceProposalStatus::PROPOSTA_REPROVADA_ID}.each do |order_service_proposal|
        # Manually create an audit record
        OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::CANCELADA_ID)
        order_service_proposal.update_columns(
          order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID,
          reproved: true,
          reason_reproved: params[:cancel_justification]
          )
      end

      # Manually create an audit record
      OrderService.generate_historic(@order_service, @current_user, @order_service.order_service_status_id, OrderServiceStatus::CANCELADA_ID)
      @order_service.update_columns(
        cancel_justification: params[:cancel_justification],
        order_service_status_id: OrderServiceStatus::CANCELADA_ID,
        km: nil
      )

      flash[:success] = OrderService.human_attribute_name(:cancel_success)
    else
      flash[:error] = OrderService.human_attribute_name(:cancel_failed)
    end
    redirect_back(fallback_location: :back)
  end

  def authorize_order_services
    authorize OrderService
    result = true
    begin
      order_service_ids = params[:order_service_ids].split(",")
      all_order_services = OrderService.where(id: [order_service_ids])
      all_order_services.each do |order_service|
        # 🔒 Autorizar apenas propostas com NOTAS_INSERIDAS (não complementos)
        order_service_proposals = order_service.order_service_proposals
        .not_complement
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::NOTAS_INSERIDAS_ID)
        order_service_proposals.each do |order_service_proposal|
          # Manually create an audit record
          OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AUTORIZADA_ID)
          order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::AUTORIZADA_ID)
        end

        # Manually create an audit record
        OrderService.generate_historic(order_service, @current_user, order_service.order_service_status_id, OrderServiceStatus::AUTORIZADA_ID)
        order_service.update_columns(order_service_status_id: OrderServiceStatus::AUTORIZADA_ID)
        
        # Envia webhook para sistema financeiro (síncrono)
        begin
          WebhookFinanceService.send_authorized_os(order_service.id)
        rescue => e
          Rails.logger.error "[OrderServices] Falha ao enviar webhook: #{e.message}"
        end
      end
      message = OrderService.human_attribute_name(:all_authorized_with_success)
    rescue Exception => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def waiting_payment_order_services
    authorize OrderService
    result = true
    begin
      order_service_ids = params[:order_service_ids].split(",")
      all_order_services = OrderService.where(id: [order_service_ids])
      all_order_services.each do |order_service|
        order_service_proposals = order_service.order_service_proposals
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::AUTORIZADA_ID)
        order_service_proposals.each do |order_service_proposal|
          # Manually create an audit record
          OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID)
          order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID)
        end

        # Manually create an audit record
        OrderService.generate_historic(order_service, @current_user, order_service.order_service_status_id, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID)
        order_service.update_columns(order_service_status_id: OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID)
      end
      message = OrderService.human_attribute_name(:all_waiting_payment_with_success)
    rescue Exception => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def make_payment_order_services
    authorize OrderService
    result = true
    begin
      order_service_ids = params[:order_service_ids].split(",")
      all_order_services = OrderService.where(id: [order_service_ids])
      all_order_services.each do |order_service|
        order_service_proposals = order_service.order_service_proposals
        .where(order_service_proposal_status_id: OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID)
        order_service_proposals.each do |order_service_proposal|
          # Manually create an audit record
          OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::PAGA_ID)
          order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::PAGA_ID)
        end

        # Manually create an audit record
        OrderService.generate_historic(order_service, @current_user, order_service.order_service_status_id, OrderServiceStatus::PAGA_ID)
        order_service.update_columns(order_service_status_id: OrderServiceStatus::PAGA_ID)
      end
      message = OrderService.human_attribute_name(:all_make_payment_with_success)
    rescue Exception => e
      result = false
      message = e.message
    end
    data = {
      result: result,
      message: message
    }
    respond_to do |format|
      format.json {render :json => data, :status => 200}
    end
  end

  def show_historic
    authorize @order_service
    @audits = @order_service.audits + @order_service.order_service_proposals.map(&:audits).flatten
    @audits.sort_by!(&:created_at)
  end

  def reject_order_service
    authorize @order_service
    @current_user.rejected_order_services << @order_service
    order_service_proposals = @order_service.order_service_proposals.select{|item| item.provider_id == @current_user.id && item.order_service_proposal_status_id == OrderServiceProposalStatus::AGUARDANDO_AVALIACAO_ID}
    order_service_proposals.each do |order_service_proposal|
      OrderServiceProposal.generate_historic(order_service_proposal, @current_user, order_service_proposal.order_service_proposal_status_id, OrderServiceProposalStatus::CANCELADA_ID)
      order_service_proposal.update_columns(order_service_proposal_status_id: OrderServiceProposalStatus::CANCELADA_ID)
    end
    flash[:success] = OrderService.human_attribute_name(:rejection_success)
    redirect_back(fallback_location: :back)
  end

  def unreject_order_service
    authorize @order_service
    @current_user.rejected_order_services.destroy(@order_service)
    flash[:success] = OrderService.human_attribute_name(:unrejection_success)
    redirect_back(fallback_location: :back)
  end

  def back_to_edit_order_service
    authorize @order_service
    old_order_service_status_id = @order_service.order_service_status_id
    @order_service.update_columns(order_service_status_id: OrderServiceStatus::EM_CADASTRO_ID)
    OrderService.generate_historic(@order_service, @current_user, old_order_service_status_id, OrderServiceStatus::EM_CADASTRO_ID)
    flash[:success] = OrderService.human_attribute_name(:back_to_edit_success)
    redirect_to edit_order_service_path(@order_service)
  end
  
  # Solicitar reavaliação de OS em Diagnóstico
  def request_reevaluation
    authorize @order_service
    
    if @order_service.request_reevaluation!(@current_user)
      flash[:success] = "OS enviada para reavaliação. O fornecedor poderá editar a proposta."
    else
      flash[:error] = "Não foi possível solicitar reavaliação para esta OS."
    end
    
    redirect_back(fallback_location: order_service_path(@order_service))
  end
  
  # Finalizar reavaliação (fornecedor conclui edição)
  def finish_reevaluation
    authorize @order_service, :edit_reevaluation?
    
    old_status = @order_service.order_service_status_id
    @order_service.update!(order_service_status_id: OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
    OrderService.generate_historic(@order_service, @current_user, old_status, OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA_ID)
    
    flash[:success] = "Reavaliação concluída. OS enviada novamente para avaliação."
    redirect_to order_service_path(@order_service)
  end

  def warranty_items_by_vehicle_id
    authorize OrderService
    vehicle_id = params[:vehicle_id]
    warranty_items = vehicle_id.present? ? get_warranty_items_for_vehicle(vehicle_id) : []
    
    respond_to do |format|
      format.json { render json: { result: warranty_items } }
    end
  end
  
  # GET /get_client_requirements
  def get_client_requirements
    client = User.find_by(id: params[:client_id])
    
    if client
      render json: {
        needs_km: client.needs_km || false,
        require_vehicle_photos: client.require_vehicle_photos || false
      }
    else
      render json: {
        needs_km: false,
        require_vehicle_photos: false
      }
    end
  end

  # GET /get_providers_for_directed_selection
  # Retorna fornecedores filtrados por estado/cidade e tipo de serviço para seleção direcionada
  def get_providers_for_directed_selection
    client_id = params[:client_id]
    provider_service_type_id = params[:provider_service_type_id]

    # Determinar o cliente (suporte para manager/additional que usam client_id)
    if @current_user.manager? || @current_user.additional?
      client = User.find_by(id: @current_user.client_id, profile_id: Profile::CLIENT_ID)
    elsif @current_user.client?
      client = @current_user
    else
      client = User.find_by(id: client_id, profile_id: Profile::CLIENT_ID)
    end

    state_ids = client&.states&.pluck(:id) || []

    providers = User.provider.active
    providers = providers.by_provider_state_ids(state_ids) if state_ids.present?

    # Filtrar por tipo de serviço se informado
    if provider_service_type_id.present?
      providers = providers.joins(:provider_service_types)
        .where(provider_service_types: { id: provider_service_type_id })
    end

    providers = providers.includes(address: [:state, :city]).name_ordered.distinct

    result = providers.map do |p|
      {
        id: p.id,
        name: p.get_name,
        state: p.address&.state&.name || 'Não informado',
        city: p.address&.city&.name || 'Não informada'
      }
    end

    render json: result
  end

  private

  def load_warranty_panel_data
    # Permite carregar itens de garantia tanto na criação (new) quanto na edição (edit)
    vehicle_id = @order_service&.vehicle_id || params[:vehicle_id]
    return if vehicle_id.blank?
    
    @warranty_items = get_warranty_items_for_vehicle(vehicle_id)
  end

  # Processar fornecedores direcionados (envio para fornecedores específicos)
  def handle_directed_providers
    # Só processa para tipos Cotação e Requisição (Diagnóstico já tem provider_id único)
    return if @order_service.order_service_type_id == OrderServiceType::DIAGNOSTICO_ID
    
    directed_flag = params.dig(:order_service, :directed_to_specific_providers)
    directed_ids = params.dig(:order_service, :directed_provider_ids)

    if directed_flag == 'true' || directed_flag == '1'
      @order_service.update_columns(directed_to_specific_providers: true)
      if directed_ids.present?
        provider_ids = directed_ids.map(&:to_i).uniq.select { |id| id > 0 }
        # Validar que os IDs são de fornecedores ativos
        valid_ids = User.provider.active.where(id: provider_ids).pluck(:id)
        @order_service.directed_provider_ids = valid_ids
      else
        @order_service.directed_providers.clear
      end
    else
      @order_service.update_columns(directed_to_specific_providers: false)
      @order_service.directed_providers.clear
    end
  end

  def get_warranty_items_for_vehicle(vehicle_id)
    return [] if vehicle_id.blank?

    today = Time.zone.today
    # Incluir apenas propostas autorizadas ou posteriores para contagem de garantia
    valid_statuses = [OrderServiceProposalStatus::AUTORIZADA_ID, OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID, OrderServiceProposalStatus::PAGA_ID]

    items = OrderServiceProposalItem
      .joins(order_service_proposal: :order_service)
      .includes(:service, order_service_proposal: [:provider, :order_service])
      .where(order_services: { vehicle_id: vehicle_id })
      .where(order_service_proposals: { order_service_proposal_status_id: valid_statuses })
      .where.not(order_service_proposal_items: { warranty_period: [nil, 0] })
      .map do |item|
        proposal = item.order_service_proposal
        
        # Usar updated_at da proposta como data de início da garantia (quando foi autorizada)
        # Para propostas autorizadas, essa é a data mais recente que reflete a autorização
        start_date = proposal.updated_at.to_date
        expires_at = start_date + item.warranty_period.days
        remaining_days = (expires_at - today).to_i
        next if remaining_days < 0

        service = item.service
        unity_value = item.unity_value || 0
        quantity = item.quantity || 1
        total_value = item.total_value || (unity_value.to_f * quantity.to_f)
        
        # Identificar se é peça ou serviço
        category_id = service&.category_id
        is_part = category_id == Category::SERVICOS_PECAS_ID

        {
          name: item.service_name.presence || service&.name,
          brand: item.brand.presence || service&.brand,
          code: service&.code,
          value: total_value,
          remaining_days: remaining_days,
          expires_at: expires_at,
          provider_name: proposal.provider&.name,
          order_service_code: proposal.order_service&.code,
          order_service_id: proposal.order_service_id,
          category_id: category_id,
          is_part: is_part,
          type_name: is_part ? 'Peça' : 'Serviço'
        }
      end
      .compact
      .sort_by { |row| [row[:is_part] ? 0 : 1, row[:expires_at]] } # Ordenar: peças primeiro, depois por data
    
    # Limitar a 15 registros
    items.take(15)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_order_service
    @order_service = OrderService.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white.
  def order_service_params
    params.require(:order_service).permit(:id,
    :order_service_status_id,
    :client_id,
    :manager_id,
    :vehicle_id,
    :provider_service_type_id,
    :maintenance_plan_id,
    :order_service_type_id,
    :provider_id,
    :km,
    :driver,
    :details,
    :code,
    :cancel_justification,
    :invoice_information,
    :invoice_part_ir,
    :invoice_part_pis,
    :invoice_part_cofins,
    :invoice_part_csll,
    :invoice_service_ir,
    :invoice_service_pis,
    :invoice_service_cofins,
    :invoice_service_csll,
    :commitment_id,
    :commitment_parts_id,
    :commitment_services_id,
    :service_group_id,
    :origin_type,
    :directed_to_specific_providers,
    part_service_order_services_attributes: [:id, :order_service_id, :service_id, :observation, :quantity, :_destroy],
    files: [],
    vehicle_photos: [],
    parts_photos: [],
    directed_provider_ids: []
    )
  end
end
