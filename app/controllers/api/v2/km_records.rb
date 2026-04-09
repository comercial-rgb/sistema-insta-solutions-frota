module Api
  module V2
    class KmRecords < Grape::API
      resource :km_records do
        before { authenticate! }

        desc 'Registrar KM de um veículo'
        params do
          requires :vehicle_id, type: Integer
          requires :km, type: Integer
          optional :origin, type: String, default: 'manual', values: %w[manual vehicle_page order_service]
          optional :observation, type: String
        end
        post do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          record = VehicleKmRecord.new(
            vehicle_id: vehicle.id,
            user_id: user.id,
            km: params[:km],
            origin: params[:origin],
            observation: params[:observation]
          )

          if record.save
            { km_record: serialize_km_record(record), message: 'KM registrado com sucesso' }
          else
            error!(record.errors.full_messages.join(', '), 422)
          end
        end

        desc 'Histórico de KM de um veículo'
        params do
          requires :vehicle_id, type: Integer
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          records = VehicleKmRecord.where(vehicle_id: vehicle.id)
                                    .order(created_at: :desc)
                                    .page(params[:page]).per(params[:per_page])

          {
            km_records: records.map { |r| serialize_km_record(r) },
            current_km: records.first&.km,
            meta: {
              current_page: records.current_page,
              total_pages: records.total_pages,
              total_count: records.total_count
            }
          }
        end
      end

      helpers do
        def serialize_km_record(r)
          {
            id: r.id,
            km: r.km,
            origin: r.origin,
            observation: r.observation,
            user_name: r.user&.name,
            order_service_code: r.order_service&.code,
            created_at: r.created_at
          }
        end
      end
    end
  end
end
