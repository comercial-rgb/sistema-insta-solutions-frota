class CiliaPricingController < ApplicationController
  before_action :set_order_service, only: [:show, :update_prices, :mark_complete, :unmark_complete]

  # GET /cilia_pricing
  # Lista todas as OS que possuem peças em orçamentos e precisam de precificação Cilia
  def index
    authorize :cilia_pricing, :index?

    @order_services = base_query

    # Filtro por período de criação
    if params[:start_date].present?
      @order_services = @order_services.where('order_services.created_at >= ?', "#{params[:start_date]} 00:00:00")
    end
    if params[:end_date].present?
      @order_services = @order_services.where('order_services.created_at <= ?', "#{params[:end_date]} 23:59:59")
    end

    # Filtro por tipo de OS
    if params[:order_service_type_id].present?
      @order_services = @order_services.where(order_service_type_id: params[:order_service_type_id])
    end

    # Filtro por status
    if params[:order_service_status_id].present?
      @order_services = @order_services.where(order_service_status_id: params[:order_service_status_id])
    end

    # Filtro por placa do veículo
    if params[:vehicle_board].present?
      @order_services = @order_services.where('vehicles.board LIKE ?', "%#{params[:vehicle_board]}%")
    end

    # Filtro: mostrar já precificadas ou não
    if params[:show_completed] == '1'
      # Mostra todas (incluindo já precificadas)
    else
      @order_services = @order_services.where(cilia_priced_at: nil)
    end

    # Ordenação
    @order_services = @order_services
      .order('order_services.created_at DESC')
      .page(params[:page])
      .per(20)

    @order_service_types = OrderServiceType.all
    @order_service_statuses = OrderServiceStatus.all

    # Estatísticas
    @stats = {
      total_pending: base_query.where(cilia_priced_at: nil).count,
      total_completed: base_query.where.not(cilia_priced_at: nil).count
    }
  end

  # GET /cilia_pricing/:id
  # Mostra OS com detalhes dos itens para precificação
  def show
    authorize :cilia_pricing, :show?

    @proposals = @order_service.order_service_proposals
      .includes(:order_service_proposal_items, :provider)
      .where.not(order_service_proposal_status_id: nil)

    @vehicle = @order_service.vehicle
    @vehicle_model = @vehicle&.vehicle_model

    # Para cada proposta, separar peças e serviços
    @proposals_data = @proposals.map do |proposal|
      items = proposal.order_service_proposal_items.includes(:service)
      
      parts = items.select { |item| item.get_category_id == Category::SERVICOS_PECAS_ID }
      services = items.select { |item| item.get_category_id == Category::SERVICOS_SERVICOS_ID }

      # Para cada peça, buscar preço de referência existente
      parts_with_reference = parts.map do |part|
        ref_price = nil
        if @vehicle_model.present? && part.service_id.present?
          ref_price = ReferencePrice.active
            .where(vehicle_model_id: @vehicle_model.id, service_id: part.service_id)
            .first
        end

        {
          item: part,
          reference_price: ref_price,
          has_reference: ref_price.present?
        }
      end

      {
        proposal: proposal,
        parts: parts_with_reference,
        services: services,
        total_parts: parts.size,
        parts_with_reference: parts_with_reference.count { |p| p[:has_reference] },
        parts_without_reference: parts_with_reference.count { |p| !p[:has_reference] }
      }
    end
  end

  # PATCH /cilia_pricing/:id/update_prices
  # Salva preços de referência Cilia para as peças
  def update_prices
    authorize :cilia_pricing, :update_prices?

    unless @order_service.vehicle&.vehicle_model_id.present?
      redirect_to cilia_pricing_show_path(@order_service),
        alert: 'Não é possível salvar preços: veículo não possui modelo vinculado. Vincule o modelo do veículo primeiro.'
      return
    end

    vehicle_model = @order_service.vehicle.vehicle_model
    success_count = 0
    error_count = 0

    if params[:reference_prices].present?
      params[:reference_prices].each do |service_id, price_data|
        next if price_data[:reference_price].blank?

        reference_price = vehicle_model.reference_prices.find_or_initialize_by(service_id: service_id)
        reference_price.assign_attributes(
          reference_price: price_data[:reference_price].to_s.gsub(',', '.'),
          max_percentage: price_data[:max_percentage].presence || 110,
          source: price_data[:source].presence || "Cilia #{Date.current.strftime('%m/%Y')}",
          active: true
        )

        if reference_price.save
          success_count += 1
        else
          error_count += 1
          Rails.logger.error "CiliaPricing: Erro ao salvar preço para service_id=#{service_id}: #{reference_price.errors.full_messages.join(', ')}"
        end
      end
    end

    if error_count == 0
      redirect_to cilia_pricing_show_path(@order_service),
        notice: "#{success_count} preço(s) de referência salvo(s) com sucesso."
    else
      redirect_to cilia_pricing_show_path(@order_service),
        alert: "#{success_count} salvo(s), #{error_count} com erro. Verifique os logs."
    end
  end

  # PATCH /cilia_pricing/:id/mark_complete
  # Marca a OS como precificada pelo Cilia
  def mark_complete
    authorize :cilia_pricing, :mark_complete?

    @order_service.update_columns(
      cilia_priced_at: Time.current,
      cilia_priced_by_id: @current_user.id
    )

    redirect_to cilia_pricing_index_path,
      notice: "OS #{@order_service.code} marcada como precificada."
  end

  # PATCH /cilia_pricing/:id/unmark_complete
  # Desmarca a OS como precificada (volta para a lista)
  def unmark_complete
    authorize :cilia_pricing, :mark_complete?

    @order_service.update_columns(
      cilia_priced_at: nil,
      cilia_priced_by_id: nil
    )

    redirect_to cilia_pricing_show_path(@order_service),
      notice: "OS #{@order_service.code} desmarcada. Voltou para a lista de pendentes."
  end

  private

  def set_order_service
    @order_service = OrderService.includes(:vehicle, :order_service_type, :order_service_status)
      .find(params[:id])
  end

  # Query base: OS que possuem propostas com itens que são peças
  def base_query
    OrderService
      .joins(:vehicle)
      .joins(order_service_proposals: { order_service_proposal_items: :service })
      .where(services: { category_id: Category::SERVICOS_PECAS_ID })
      .where('order_services.created_at >= ?', '2026-03-06 00:00:00')
      .includes(:order_service_type, :order_service_status, vehicle: :vehicle_model)
      .distinct
  end
end
