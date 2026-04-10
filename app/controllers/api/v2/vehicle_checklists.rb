module Api
  module V2
    class VehicleChecklists < Grape::API
      resource :vehicle_checklists do
        before { authenticate! }

        desc 'Lista checklists de veículos'
        params do
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 20
          optional :vehicle_id, type: Integer
          optional :status, type: String
        end
        get do
          user = current_user
          scope = checklist_scope(user)
          scope = scope.by_vehicle(params[:vehicle_id]) if params[:vehicle_id].present?
          scope = scope.by_status(params[:status]) if params[:status].present?

          checklists = scope.recent.includes(:vehicle, :user, :items).page(params[:page]).per(params[:per_page])

          {
            checklists: checklists.map { |c| serialize_checklist(c) },
            meta: {
              current_page: checklists.current_page,
              total_pages: checklists.total_pages,
              total_count: checklists.total_count
            }
          }
        end

        desc 'Detalhes de um checklist'
        get ':id' do
          user = current_user
          checklist = checklist_scope(user).find(params[:id])

          { checklist: serialize_checklist_detail(checklist) }
        end

        desc 'Criar checklist de veículo'
        params do
          requires :vehicle_id, type: Integer
          optional :current_km, type: Integer
          optional :general_notes, type: String
          optional :photos, type: Array[File]
          requires :items, type: Array do
            requires :category, type: String, values: VehicleChecklistItem::CATEGORIES
            requires :item_name, type: String
            requires :condition, type: String, values: VehicleChecklistItem::CONDITIONS
            optional :observation, type: String
            optional :has_anomaly, type: Boolean, default: false
          end
        end
        post do
          user = current_user
          client_id = resolve_client_id(user)
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          checklist = VehicleChecklist.new(
            vehicle: vehicle,
            user: user,
            client_id: client_id,
            cost_center_id: vehicle.cost_center_id,
            current_km: params[:current_km],
            general_notes: params[:general_notes],
            status: 'pending'
          )

          params[:items].each do |item_params|
            checklist.items.build(
              category: item_params[:category],
              item_name: item_params[:item_name],
              condition: item_params[:condition],
              observation: item_params[:observation],
              has_anomaly: item_params[:has_anomaly] || item_params[:condition].in?(%w[attention critical])
            )
          end

          if params[:photos].present?
            params[:photos].each { |photo| checklist.photos.attach(photo) }
          end

          if checklist.save
            # Registrar KM se informado
            if params[:current_km].present? && params[:current_km] > 0
              VehicleKmRecord.create(
                vehicle: vehicle,
                user: user,
                km: params[:current_km],
                origin: 'checklist',
                observation: "Registrado via checklist ##{checklist.id}"
              )
            end

            { checklist: serialize_checklist(checklist), message: 'Checklist registrado com sucesso' }
          else
            error!(checklist.errors.full_messages.join(', '), 422)
          end
        end

        desc 'Dar ciência no checklist (gestor/admin)'
        put ':id/acknowledge' do
          user = current_user
          unless user.admin? || user.manager? || user.additional?
            error!('Sem permissão para dar ciência', 403)
          end

          checklist = checklist_scope(user).find(params[:id])
          checklist.acknowledge!(user)

          { checklist: serialize_checklist(checklist), message: 'Ciência registrada com sucesso' }
        end

        desc 'Criar OS a partir do checklist'
        params do
          optional :details, type: String
        end
        post ':id/create_os' do
          user = current_user
          unless user.admin? || user.manager? || user.additional?
            error!('Sem permissão para criar OS', 403)
          end

          checklist = checklist_scope(user).find(params[:id])
          client_id = checklist.client_id

          # Montar descrição da OS com itens do checklist com anomalia
          anomaly_items = checklist.items.where(has_anomaly: true)
          details = "OS gerada a partir do Checklist ##{checklist.id}\n\n"
          details += "Veículo: #{checklist.vehicle.board} - #{checklist.vehicle.brand} #{checklist.vehicle.model}\n"
          details += "Realizado por: #{checklist.user.name}\n"
          details += "Data: #{checklist.created_at.strftime('%d/%m/%Y %H:%M')}\n"
          details += "KM: #{checklist.current_km}\n\n" if checklist.current_km.present?
          details += "=== ITENS COM ANOMALIA ===\n"
          anomaly_items.each do |item|
            details += "- [#{item.category.upcase}] #{item.item_name}: #{item.condition} #{item.observation.present? ? "- #{item.observation}" : ''}\n"
          end
          details += "\n#{params[:details]}" if params[:details].present?
          details += "\nNotas gerais: #{checklist.general_notes}" if checklist.general_notes.present?

          os = OrderService.new(
            vehicle_id: checklist.vehicle_id,
            client_id: client_id,
            cost_center_id: checklist.cost_center_id,
            driver: checklist.user.name,
            km: checklist.current_km,
            details: details,
            order_service_status_id: 1,
            origin_type: 'checklist'
          )

          if os.save
            checklist.create_os_from_checklist!(os)
            { order_service: { id: os.id, code: os.code }, message: 'OS criada com sucesso a partir do checklist' }
          else
            error!(os.errors.full_messages.join(', '), 422)
          end
        end
      end

      helpers do
        def resolve_client_id(user)
          if user.client?
            user.id
          elsif user.driver?
            user.client_id
          else
            user.client_id
          end
        end

        def checklist_scope(user)
          if user.admin?
            VehicleChecklist.all
          elsif user.driver?
            VehicleChecklist.where(user_id: user.id)
          elsif user.client?
            VehicleChecklist.where(client_id: user.id)
          else
            VehicleChecklist.where(client_id: user.client_id)
          end
        end

        def serialize_checklist(c)
          {
            id: c.id,
            vehicle_board: c.vehicle&.board,
            vehicle_model: "#{c.vehicle&.brand} #{c.vehicle&.model}",
            user_name: c.user&.name,
            current_km: c.current_km,
            status: c.status,
            anomaly_count: c.anomaly_count,
            has_anomalies: c.has_anomalies?,
            items_count: c.items.size,
            has_photos: c.photos.attached?,
            created_at: c.created_at,
            acknowledged_at: c.acknowledged_at,
            acknowledged_by: c.acknowledged_by&.name,
            order_service_id: c.order_service_id,
            order_service_code: c.order_service&.code
          }
        end

        def serialize_checklist_detail(c)
          serialize_checklist(c).merge(
            general_notes: c.general_notes,
            vehicle_id: c.vehicle_id,
            cost_center: c.cost_center&.name,
            items: c.items.map do |item|
              {
                id: item.id,
                category: item.category,
                item_name: item.item_name,
                condition: item.condition,
                observation: item.observation,
                has_anomaly: item.has_anomaly
              }
            end,
            photos: c.photos.map { |p| Rails.application.routes.url_helpers.rails_blob_url(p, only_path: true) }
          )
        end
      end
    end
  end
end
