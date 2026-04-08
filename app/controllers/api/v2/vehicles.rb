module Api
  module V2
    class Vehicles < Grape::API
      resource :vehicles do
        before { authenticate! }

        desc 'Lista veículos do cliente'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :search, type: String
          optional :active, type: Boolean
          optional :cost_center_id, type: Integer
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

          scope = Vehicle.where(client_id: client_id)
          scope = scope.where(active: params[:active]) if params[:active] != nil
          scope = scope.where(cost_center_id: params[:cost_center_id]) if params[:cost_center_id].present?

          if params[:search].present?
            search = "%#{params[:search]}%"
            scope = scope.where('vehicles.board LIKE ? OR vehicles.brand LIKE ? OR vehicles.model LIKE ?', search, search, search)
          end

          vehicles = scope.order(:board).page(params[:page]).per(params[:per_page])

          {
            vehicles: vehicles.map { |v| serialize_vehicle(v) },
            meta: {
              current_page: vehicles.current_page,
              total_pages: vehicles.total_pages,
              total_count: vehicles.total_count
            }
          }
        end

        desc 'Detalhes de um veículo'
        get ':id' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:id])

          last_km = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).first
          km_history = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).limit(10)
          pending_alerts = MaintenanceAlert.where(vehicle_id: vehicle.id).pending
          recent_os = vehicle.order_services.order(created_at: :desc).limit(5)

          {
            vehicle: serialize_vehicle(vehicle),
            current_km: last_km&.km,
            km_history: km_history.map { |r| { id: r.id, km: r.km, origin: r.origin, date: r.created_at, user: r.user&.name } },
            pending_alerts: pending_alerts.map { |a| { id: a.id, message: a.message, alert_type: a.alert_type, target_km: a.target_km, target_date: a.target_date } },
            recent_os: recent_os.map { |os| { id: os.id, code: os.code, status: os.order_service_status&.name, km: os.km, created_at: os.created_at } }
          }
        end
      end

      helpers do
        def serialize_vehicle(v)
          {
            id: v.id,
            board: v.board,
            brand: v.brand,
            model: v.model,
            year: v.year,
            color: v.color,
            renavam: v.renavam,
            chassi: v.chassi,
            market_value: v.market_value&.to_f,
            acquisition_date: v.acquisition_date,
            active: v.active,
            fuel_type: v.fuel_type&.name,
            vehicle_type: v.vehicle_type&.name,
            cost_center: v.cost_center&.name,
            sub_unit: v.sub_unit&.name,
            model_year: v.model_year
          }
        end
      end
    end
  end
end
