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

      # Para cada peça, buscar preço de referência e histórico
      parts_with_reference = parts.map do |part|
        ref_price = nil
        if @vehicle_model.present? && part.service_id.present?
          ref_price = ReferencePrice.active
            .where(vehicle_model_id: @vehicle_model.id, service_id: part.service_id)
            .first
        end

        historical = fetch_historical_prices(@order_service, part.service_id)

        {
          item: part,
          reference_price: ref_price,
          has_reference: ref_price.present?,
          sem_tabela: ref_price&.sem_tabela? || false,
          historical_prices: historical[:prices],
          historical_avg: historical[:avg],
          historical_count: historical[:count]
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
  # Salva preços de referência Cilia para as peças (parcial ou total)
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
        sem_tabela = price_data[:sem_tabela].to_s == '1'
        # Skip se nem sem_tabela foi marcado nem preço foi preenchido
        next if !sem_tabela && price_data[:reference_price].blank?

        reference_price = vehicle_model.reference_prices.find_or_initialize_by(service_id: service_id)

        if sem_tabela
          reference_price.assign_attributes(sem_tabela: true, reference_price: nil, max_percentage: nil, active: true,
            reference_code: price_data[:reference_code].presence,
            source: price_data[:source].presence || "Sem ref. tabela #{Date.current.strftime('%m/%Y')}")
        else
          reference_price.assign_attributes(
            sem_tabela: false,
            reference_price: parse_price_input(price_data[:reference_price]),
            max_percentage: price_data[:max_percentage].presence || 110,
            reference_code: price_data[:reference_code].presence,
            source: price_data[:source].presence || "Cilia #{Date.current.strftime('%m/%Y')}",
            active: true
          )
        end

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

  # GET /cilia_pricing/sem_tabela_report
  # Lista todas as ReferencePrice com sem_tabela=true agrupadas por modelo de veículo
  def sem_tabela_report
    authorize :cilia_pricing, :sem_tabela_report?

    records = ReferencePrice
      .where(sem_tabela: true, active: true)
      .includes(:vehicle_model, :service)
      .order('vehicle_models.name, services.name')
      .joins(:vehicle_model, :service)

    @by_model = records.group_by(&:vehicle_model)
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

  # Converte string de preço em formato brasileiro ("5.500,00") para decimal ("5500.00").
  # Quando há vírgula, trata pontos como separadores de milhar e vírgula como decimal.
  def parse_price_input(value)
    str = value.to_s.strip
    return str if str.blank?
    if str.include?(',')
      str.gsub('.', '').gsub(',', '.')
    else
      str
    end
  end

  def set_order_service
    @order_service = OrderService.includes(:vehicle, :order_service_type, :order_service_status)
      .find(params[:id])
  end

  # Busca últimas 3 cotações aprovadas do mesmo veículo para o mesmo serviço
  def fetch_historical_prices(order_service, service_id)
    return { prices: [], avg: nil, count: 0 } if service_id.blank? || order_service.vehicle_id.blank?

    last_os_ids = OrderService
      .joins(:order_service_proposals)
      .where(vehicle_id: order_service.vehicle_id)
      .where.not(id: order_service.id)
      .where(order_service_proposals: { order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES })
      .order(created_at: :desc)
      .limit(3)
      .distinct
      .pluck(:id)

    return { prices: [], avg: nil, count: 0 } if last_os_ids.empty?

    prices = OrderServiceProposalItem
      .joins(order_service_proposal: :order_service)
      .where(service_id: service_id)
      .where(order_service_proposals: {
        order_service_id: last_os_ids,
        order_service_proposal_status_id: OrderServiceProposalStatus::REQUIRED_PROPOSAL_STATUSES
      })
      .pluck(:unity_value)
      .map(&:to_f)
      .reject(&:zero?)

    avg = prices.any? ? (prices.sum / prices.size).round(2) : nil
    { prices: prices, avg: avg, count: prices.size }
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
