class PerformanceBenchmarkController < ApplicationController
  before_action :ensure_admin_or_manager

  SLA_MS = 2000.0

  def index
    @results  = []
    @started_at = Time.current

    run_benchmark('Listagem de Ordens de Serviço (50 registros)') do
      OrderService.includes(:vehicle, :order_service_status, :order_service_type, :client)
                  .where(client_id: benchmark_client_ids)
                  .order(updated_at: :desc)
                  .limit(50)
                  .load
    end

    run_benchmark('Listagem de Veículos (50 registros)') do
      Vehicle.includes(:client, :cost_center, :vehicle_type, :fuel_type)
             .where(client_id: benchmark_client_ids)
             .order(:board)
             .limit(50)
             .load
    end

    run_benchmark('Propostas por OS (join multi-tabela)') do
      OrderServiceProposal
        .joins(:order_service)
        .includes(:provider, :order_service_proposal_status,
                  order_service_proposal_items: :service)
        .where(order_services: { client_id: benchmark_client_ids })
        .where(is_complement: false)
        .order(created_at: :desc)
        .limit(50)
        .load
    end

    run_benchmark('Dashboard — contagens por status') do
      ids = benchmark_client_ids
      OrderServiceStatus.all.map do |s|
        OrderService.where(client_id: ids, order_service_status_id: s.id).count
      end
    end

    run_benchmark('Relatório por Estabelecimento (GROUP BY)') do
      valid_statuses = [
        OrderServiceProposalStatus::APROVADA_ID,
        OrderServiceProposalStatus::NOTAS_INSERIDAS_ID,
        OrderServiceProposalStatus::AUTORIZADA_ID,
        OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID,
        OrderServiceProposalStatus::PAGA_ID
      ]
      OrderServiceProposal
        .joins(:order_service)
        .joins("INNER JOIN users AS pvs ON pvs.id = order_service_proposals.provider_id")
        .where(is_complement: false)
        .where(order_service_proposal_status_id: valid_statuses)
        .where(order_services: { client_id: benchmark_client_ids })
        .group("order_service_proposals.provider_id")
        .select("order_service_proposals.provider_id,
                 COUNT(order_service_proposals.id) AS transactions_count,
                 SUM(order_service_proposals.total_value_without_discount) AS gross_value,
                 SUM(order_service_proposals.total_value) AS net_value")
        .load
    end

    run_benchmark('Histórico de audits de OS') do
      Audited::Audit
        .where(auditable_type: 'OrderService')
        .order(created_at: :desc)
        .limit(100)
        .load
    end

    run_benchmark('Saldo de empenhos por centro de custo') do
      ids = benchmark_client_ids
      CostCenter.where(client_id: ids).includes(:commitments).limit(20).load
    end

    @total_ms = ((Time.current - @started_at) * 1000).round(1)
    @pass_count = @results.count { |r| r[:pass] }
    @fail_count = @results.count { |r| !r[:pass] }
    @overall_pass = @results.all? { |r| r[:pass] }
  end

  private

  def run_benchmark(label)
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    records = yield
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round(1)
    count = records.respond_to?(:length) ? records.length : records.to_i

    @results << {
      label:    label,
      ms:       duration_ms,
      pass:     duration_ms < SLA_MS,
      count:    count
    }
  rescue => e
    @results << {
      label:  label,
      ms:     nil,
      pass:   false,
      count:  0,
      error:  e.message.truncate(120)
    }
  end

  def benchmark_client_ids
    @benchmark_client_ids ||= if @current_user.admin?
      User.client.active.limit(10).pluck(:id)
    elsif @current_user.client?
      [@current_user.id]
    else
      [@current_user.client_id].compact
    end
  end

  def ensure_admin_or_manager
    unless @current_user.admin? || @current_user.manager? || @current_user.additional?
      flash[:alert] = 'Acesso restrito.'
      redirect_to root_path
    end
  end
end
