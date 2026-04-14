module Api
  module V2
    class TrafficViolationsEndpoint < Grape::API
      resource :traffic_violations do
        before { authenticate! }

        desc 'Lista multas'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :vehicle_id, type: Integer
          optional :user_id, type: Integer
          optional :status, type: String
        end
        get do
          user = current_user
          scope = violations_scope(user)
          scope = scope.by_vehicle(params[:vehicle_id]) if params[:vehicle_id].present?
          scope = scope.by_user(params[:user_id]) if params[:user_id].present?
          scope = scope.by_status(params[:status]) if params[:status].present?

          violations = scope.recent.includes(:user, :vehicle).page(params[:page]).per(params[:per_page])

          {
            traffic_violations: violations.map { |v| serialize_violation(v) },
            meta: {
              current_page: violations.current_page,
              total_pages: violations.total_pages,
              total_count: violations.total_count
            }
          }
        end

        desc 'Detalhes de uma multa'
        get ':id' do
          violation = violations_scope(current_user).find(params[:id])
          { traffic_violation: serialize_violation(violation) }
        end

        desc 'Registrar multa'
        params do
          requires :user_id, type: Integer, desc: 'ID do motorista'
          requires :vehicle_id, type: Integer
          requires :violation_date, type: Date
          optional :violation_type, type: String, values: TrafficViolation::VIOLATION_TYPES
          optional :description, type: String
          optional :fine_value, type: Float
          optional :points, type: Integer
          optional :auto_number, type: String
          optional :due_date, type: Date
          optional :notes, type: String
        end
        post do
          user = current_user
          unless user.admin? || user.manager? || user.additional?
            error!('Sem permissão para registrar multas', 403)
          end

          client_id = user.client? ? user.id : user.client_id

          violation = TrafficViolation.new(
            user_id: params[:user_id],
            vehicle_id: params[:vehicle_id],
            client_id: client_id,
            violation_date: params[:violation_date],
            violation_type: params[:violation_type],
            description: params[:description],
            fine_value: params[:fine_value],
            points: params[:points],
            auto_number: params[:auto_number],
            due_date: params[:due_date],
            notes: params[:notes]
          )

          if violation.save
            { traffic_violation: serialize_violation(violation), message: 'Multa registrada com sucesso' }
          else
            error!(violation.errors.full_messages.join(', '), 422)
          end
        end

        desc 'Atualizar multa'
        params do
          optional :status, type: String, values: TrafficViolation::STATUSES
          optional :paid_at, type: Date
          optional :notes, type: String
        end
        put ':id' do
          user = current_user
          unless user.admin? || user.manager? || user.additional?
            error!('Sem permissão', 403)
          end

          violation = violations_scope(user).find(params[:id])
          updates = declared(params, include_missing: false).except(:id)
          violation.update!(updates)

          { traffic_violation: serialize_violation(violation), message: 'Multa atualizada' }
        end
      end

      helpers do
        def violations_scope(user)
          if user.admin?
            TrafficViolation.all
          elsif user.driver?
            TrafficViolation.where(user_id: user.id)
          elsif user.client?
            TrafficViolation.where(client_id: user.id)
          else
            TrafficViolation.where(client_id: user.client_id)
          end
        end

        def serialize_violation(v)
          {
            id: v.id,
            auto_number: v.auto_number,
            violation_date: v.violation_date,
            violation_type: v.violation_type,
            description: v.description,
            fine_value: v.fine_value&.to_f,
            points: v.points,
            status: v.status,
            due_date: v.due_date,
            paid_at: v.paid_at,
            notes: v.notes,
            driver_name: v.user&.name,
            vehicle_board: v.vehicle&.board,
            vehicle_model: "#{v.vehicle&.brand} #{v.vehicle&.model}",
            created_at: v.created_at
          }
        end
      end
    end
  end
end
