module Api
  module V2
    class QrNfcServices < Grape::API
      resource :qr_nfc do
        before { authenticate! }

        desc 'Solicitar serviço via QR Code / NFC'
        params do
          requires :token, type: String, desc: 'Token do QR Code ou NFC do veículo'
          requires :provider_service_type_id, type: Integer
          requires :details, type: String
          optional :km, type: Integer
          optional :driver, type: String
        end
        post 'request_service' do
          user = current_user
          client = user.profile_id == Profile::CLIENT_ID ? user : User.find(user.client_id)

          unless client.qr_nfc_enabled
            error!('Funcionalidade QR/NFC não habilitada para este cliente', 403)
          end

          # Decodificar token - formato: "VH-{vehicle_id}-{hash}"
          parts = params[:token].to_s.split('-')
          error!('Token QR/NFC inválido', 422) unless parts.length >= 3 && parts[0] == 'VH'

          vehicle_id = parts[1].to_i
          vehicle = Vehicle.where(client_id: client.id, id: vehicle_id).first
          error!('Veículo não encontrado ou não pertence ao cliente', 404) unless vehicle

          # Verificar hash do token
          expected_token = Digest::SHA256.hexdigest("#{vehicle.id}-#{vehicle.board}-#{client.id}")[0..7]
          error!('Token QR/NFC inválido', 422) unless parts[2] == expected_token

          # Validar KM
          if params[:km].present?
            last_km = VehicleKmRecord.where(vehicle_id: vehicle.id).order(created_at: :desc).first
            if last_km && params[:km] < last_km.km
              error!("KM informado (#{params[:km]}) é menor que o último registro (#{last_km.km})", 422)
            end
          end

          os = OrderService.create!(
            client_id: client.id,
            vehicle_id: vehicle.id,
            provider_service_type_id: params[:provider_service_type_id],
            order_service_type_id: OrderServiceType::COTACOES_ID,
            order_service_status_id: OrderServiceStatus::EM_CADASTRO_ID,
            km: params[:km],
            driver: params[:driver] || user.name,
            details: params[:details],
            origin_type: 'qr_nfc'
          )

          if params[:km].present?
            VehicleKmRecord.create!(
              vehicle_id: vehicle.id,
              user_id: user.id,
              order_service_id: os.id,
              km: params[:km],
              origin: 'order_service'
            )
          end

          {
            order_service: {
              id: os.id,
              code: os.code,
              vehicle: { board: vehicle.board, model: vehicle.model },
              status: 'EM_CADASTRO'
            },
            message: 'OS criada via QR/NFC com sucesso'
          }
        end

        desc 'Gerar token QR Code para veículo (admin/gestor)'
        params do
          requires :vehicle_id, type: Integer
        end
        post 'generate_token' do
          user = current_user
          unless user.profile_id.in?([Profile::ADMIN_ID, Profile::MANAGER_ID, Profile::CLIENT_ID])
            error!('Sem permissão', 403)
          end

          client_id = user.profile_id == Profile::CLIENT_ID ? user.id : user.client_id
          vehicle = Vehicle.where(client_id: client_id).find(params[:vehicle_id])

          hash = Digest::SHA256.hexdigest("#{vehicle.id}-#{vehicle.board}-#{client_id}")[0..7]
          token = "VH-#{vehicle.id}-#{hash}"

          { token: token, vehicle: { id: vehicle.id, board: vehicle.board, model: vehicle.model } }
        end

        desc 'Verificar se QR/NFC está habilitado'
        get 'status' do
          user = current_user
          client = user.profile_id == Profile::CLIENT_ID ? user : User.find(user.client_id)

          { enabled: client.qr_nfc_enabled }
        end
      end
    end
  end
end
