module Api
  module V2
    class Dashboard < Grape::API
      resource :dashboard do
        before { authenticate! }

        desc 'Retorna dados do dashboard para o usuário mobile'
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

          os_scope = OrderService.where(client_id: client_id)

          total_os = os_scope.count
          os_open = os_scope.where(order_service_status_id: [
            OrderServiceStatus::EM_ABERTO,
            OrderServiceStatus::EM_CADASTRO
          ]).count
          os_approved = os_scope.where(order_service_status_id: OrderServiceStatus::APROVADA).count
          os_awaiting = os_scope.where(order_service_status_id: [
            OrderServiceStatus::AGUARDANDO_AVALIACAO_PROPOSTA,
            OrderServiceStatus::AGUARDANDO_APROVACAO_COMPLEMENTO
          ]).count
          os_paid = os_scope.where(order_service_status_id: OrderServiceStatus::PAGA).count
          os_cancelled = os_scope.where(order_service_status_id: OrderServiceStatus::CANCELADA).count

          vehicles_count = Vehicle.where(client_id: client_id, active: true).count
          anomalies_open = Anomaly.where(client_id: client_id).open_anomalies.count
          pending_alerts = MaintenanceAlert.where(client_id: client_id).pending.count

          # OS por mês (últimos 6 meses)
          os_by_month = os_scope
            .where('order_services.created_at >= ?', 6.months.ago)
            .group("DATE_FORMAT(order_services.created_at, '%Y-%m')")
            .count
            .map { |k, v| { month: k, count: v } }

          # Valores aprovados por tipo de serviço
          os_values_by_type = os_scope
            .joins(:order_service_type)
            .where(order_service_status_id: [
              OrderServiceStatus::APROVADA,
              OrderServiceStatus::AUTORIZADA,
              OrderServiceStatus::PAGA
            ])
            .joins(order_service_proposals: :order_service_proposal_items)
            .group('order_service_types.name')
            .sum('order_service_proposal_items.total_value')
            .map { |k, v| { type: k, value: v.to_f } }

          {
            summary: {
              total_os: total_os,
              os_open: os_open,
              os_approved: os_approved,
              os_awaiting_approval: os_awaiting,
              os_paid: os_paid,
              os_cancelled: os_cancelled,
              vehicles_count: vehicles_count,
              anomalies_open: anomalies_open,
              pending_maintenance_alerts: pending_alerts
            },
            os_by_month: os_by_month,
            os_values_by_type: os_values_by_type,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              profile_id: user.profile_id,
              client_id: client_id,
              qr_nfc_enabled: user.respond_to?(:qr_nfc_enabled) ? user.qr_nfc_enabled : false
            }
          }
        end
      end
    end
  end
end
