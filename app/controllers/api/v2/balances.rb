module Api
  module V2
    class Balances < Grape::API
      resource :balances do
        before { authenticate! }

        desc 'Lista saldos/empenhos'
        params do
          optional :cost_center_id, type: Integer
          optional :contract_id, type: Integer
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

          # Saldos por centro de custo
          cost_centers = CostCenter.where(client_id: client_id)
          cost_centers = cost_centers.where(id: params[:cost_center_id]) if params[:cost_center_id].present?

          balances = cost_centers.map do |cc|
            commitments = cc.commitments.includes(:contract)
            total_committed = commitments.sum(:commitment_value)
            total_cancelled = commitments.sum(:canceled_value)

            # Valor consumido (OS pagas)
            consumed = OrderService.where(commitment_id: commitments.pluck(:id))
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
                {
                  id: c.id,
                  number: c.commitment_number,
                  value: c.commitment_value&.to_f,
                  cancelled: c.canceled_value&.to_f,
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
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id

          contracts = Contract.where(client_id: client_id).order(created_at: :desc)

          {
            contracts: contracts.map do |c|
              {
                id: c.id,
                name: c.name,
                number: c.number,
                initial_date: c.initial_date,
                final_date: c.final_date,
                total_value: c.total_value&.to_f,
                active: c.active,
                commitments_count: c.commitments.count
              }
            end
          }
        end
      end
    end
  end
end
