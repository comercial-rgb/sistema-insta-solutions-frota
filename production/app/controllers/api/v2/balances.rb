module Api
  module V2
    class Balances < Grape::API
      resource :balances do
        before { authenticate! }

        desc 'Lista saldos/empenhos'
        params do
          optional :cost_center_id, type: Integer
          optional :contract_id, type: Integer
          optional :client_id, type: Integer
        end
        get do
          user = current_user
          if user.admin? && params[:client_id].present?
            client_id = params[:client_id]
          else
            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          end

          # Saldos por centro de custo
          cost_centers = CostCenter.where(client_id: client_id)
          cost_centers = cost_centers.where(id: params[:cost_center_id]) if params[:cost_center_id].present?

          balances = cost_centers.map do |cc|
            # Une empenhos legados (cost_center_id direto) + N:N (commitment_cost_centers)
            commitment_ids = (cc.commitments.pluck(:id) + cc.linked_commitments.pluck(:id)).uniq
            commitments = Commitment.where(id: commitment_ids).includes(:contract, :category)
            total_committed = commitments.sum(:commitment_value)
            total_cancelled = commitments.sum(:canceled_value)

            # Valor consumido (OS pagas)
            consumed = OrderService.unscoped.where(commitment_id: commitment_ids)
                                    .where(order_service_status_id: [
                                      OrderServiceStatus::PAGA_ID,
                                      OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
                                      OrderServiceStatus::AUTORIZADA_ID
                                    ])
                                    .joins(order_service_proposals: :order_service_proposal_items)
                                    .sum('order_service_proposal_items.total_value')

            {
              cost_center: { id: cc.id, name: cc.name },
              budget_value: cc.budget_value&.to_f || 0,
              total_committed: total_committed.to_f,
              total_cancelled: total_cancelled.to_f,
              total_consumed: consumed.to_f,
              available: (total_committed - total_cancelled - consumed).to_f,
              commitments: commitments.map do |c|
                c_consumed = OrderService.unscoped.where(commitment_id: c.id)
                                          .where(order_service_status_id: [
                                            OrderServiceStatus::PAGA_ID,
                                            OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID,
                                            OrderServiceStatus::AUTORIZADA_ID
                                          ])
                                          .joins(order_service_proposals: :order_service_proposal_items)
                                          .sum('order_service_proposal_items.total_value').to_f
                c_value = c.commitment_value.to_f
                c_cancel = c.canceled_value.to_f
                c_available = c_value - c_cancel - c_consumed
                {
                  id: c.id,
                  number: c.commitment_number,
                  value: c_value,
                  cancelled: c_cancel,
                  consumed: c_consumed,
                  available: c_available,
                  active: c.active,
                  category: c.category ? { id: c.category.id, name: c.category.name } : nil,
                  contract: c.contract ? { id: c.contract.id, name: c.contract.name, number: c.contract.number } : nil
                }
              end
            }
          end

          # Resumo geral
          total_budget = balances.sum { |b| b[:budget_value] }
          total_committed = balances.sum { |b| b[:total_committed] }
          total_consumed = balances.sum { |b| b[:total_consumed] }
          total_available = balances.sum { |b| b[:available] }

          {
            summary: {
              total_budget: total_budget,
              total_committed: total_committed,
              total_consumed: total_consumed,
              total_available: total_available
            },
            balances: balances
          }
        end

        desc 'Contratos do cliente'
        get 'contracts' do
          user = current_user
          if user.admin? && params[:client_id].present?
            client_id = params[:client_id]
          else
            client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          end

          contracts = Contract.where(client_id: client_id).order(created_at: :desc)

          {
            contracts: contracts.map do |c|
              total_value = c.respond_to?(:get_total_value) ? c.get_total_value.to_f : c.total_value.to_f
              used_value = c.respond_to?(:get_used_value) ? c.get_used_value(nil).to_f : 0.0
              available_value = (total_value - used_value).to_f
              {
                id: c.id,
                name: c.name,
                number: c.number,
                initial_date: c.initial_date,
                final_date: c.final_date,
                total_value: total_value,
                used_value: used_value,
                available_value: available_value,
                active: c.active,
                commitments_count: c.commitments.count,
                commitments: c.commitments.map do |cm|
                  {
                    id: cm.id,
                    number: cm.commitment_number,
                    value: cm.commitment_value.to_f,
                    cancelled: cm.canceled_value.to_f,
                    active: cm.active
                  }
                end
              }
            end
          }
        end
      end
    end
  end
end
