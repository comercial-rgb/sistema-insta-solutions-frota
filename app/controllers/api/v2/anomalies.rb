module Api
  module V2
    class Anomalies < Grape::API
      resource :anomalies do
        before { authenticate! }

        desc 'Lista anomalias'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :status, type: String
          optional :severity, type: String
          optional :vehicle_id, type: Integer
        end
        get do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id

          scope = Anomaly.where(client_id: client_id)
          scope = scope.by_status(params[:status]) if params[:status].present?
          scope = scope.by_severity(params[:severity]) if params[:severity].present?
          scope = scope.by_vehicle(params[:vehicle_id]) if params[:vehicle_id].present?

          anomalies = scope.recent.page(params[:page]).per(params[:per_page])

          {
            anomalies: anomalies.map { |a| serialize_anomaly(a) },
            meta: {
              current_page: anomalies.current_page,
              total_pages: anomalies.total_pages,
              total_count: anomalies.total_count
            }
          }
        end

        desc 'Detalhes de uma anomalia'
        get ':id' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          anomaly = Anomaly.where(client_id: client_id).find(params[:id])

          { anomaly: serialize_anomaly_detail(anomaly) }
        end

        desc 'Relatar anomalia/necessidade de manutenção'
        params do
          requires :vehicle_id, type: Integer
          requires :title, type: String
          requires :description, type: String
          optional :severity, type: String, default: 'medium', values: Anomaly::SEVERITIES
          optional :category, type: String, values: Anomaly::CATEGORIES
          optional :photos, type: Array[File]
        end
        post do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          anomaly = Anomaly.new(
            vehicle_id: vehicle.id,
            user_id: user.id,
            client_id: client_id,
            cost_center_id: vehicle.cost_center_id,
            title: params[:title],
            description: params[:description],
            severity: params[:severity],
            category: params[:category]
          )

          if params[:photos].present?
            params[:photos].each do |photo|
              anomaly.photos.attach(photo)
            end
          end

          if anomaly.save
            { anomaly: serialize_anomaly(anomaly), message: 'Anomalia relatada com sucesso' }
          else
            error!(anomaly.errors.full_messages.join(', '), 422)
          end
        end

        desc 'Atualizar status de anomalia (gestor/admin)'
        params do
          optional :status, type: String, values: Anomaly::STATUSES
          optional :resolution_notes, type: String
        end
        put ':id' do
          user = current_user
          client_id = user.profile_id == Profile::CLIENTE ? user.id : user.client_id
          anomaly = Anomaly.where(client_id: client_id).find(params[:id])

          updates = {}
          updates[:status] = params[:status] if params[:status].present?
          updates[:resolution_notes] = params[:resolution_notes] if params[:resolution_notes].present?

          if params[:status] == 'resolved'
            updates[:resolved_at] = Time.current
            updates[:resolved_by_id] = user.id
          end

          anomaly.update!(updates)
          { anomaly: serialize_anomaly(anomaly), message: 'Anomalia atualizada' }
        end
      end

      helpers do
        def serialize_anomaly(a)
          {
            id: a.id,
            title: a.title,
            description: a.description,
            severity: a.severity,
            status: a.status,
            category: a.category,
            vehicle_board: a.vehicle&.board,
            vehicle_model: a.vehicle&.model,
            user_name: a.user&.name,
            created_at: a.created_at,
            has_photos: a.photos.attached?
          }
        end

        def serialize_anomaly_detail(a)
          base = serialize_anomaly(a)
          base.merge(
            cost_center: a.cost_center&.name,
            resolved_at: a.resolved_at,
            resolved_by: a.resolved_by&.name,
            resolution_notes: a.resolution_notes,
            photos: a.photos.attached? ? a.photos.map { |p| Rails.application.routes.url_helpers.rails_blob_url(p, only_path: true) } : []
          )
        end
      end
    end
  end
end
