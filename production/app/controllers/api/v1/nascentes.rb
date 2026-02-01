module Api  
  module V1
    class Nascentes < Grape::API
      include Api::V1::Defaults

      resource :nascentes do

        get "" do
          # begin
          #   Rails.logger.info "-- Requisição nascentes --"
          #   path = "#{Rails.root}/tmp/request-"+DateTime.now.to_s+".txt"
          #   File.open(path, "w+") do |f|
          #     f.write(params)
          #   end
          #   Rails.logger.info "-- Escreveu no arquivo nascentes --"
          #   return {status: 'success'}
          # rescue Exception => e
          #   Rails.logger.error "-- Requisição nascentes ERRO -- "+e.message
          #   return {status: 'failed', errors: e.message}
          # end
        end

        post "" do
          # begin
          #   Rails.logger.info "-- Requisição nascentes --"
          #   path = "#{Rails.root}/tmp/request-"+DateTime.now.to_s+".txt"
          #   File.open(path, "w+") do |f|
          #     f.write(params)
          #   end
          #   Rails.logger.info "-- Escreveu no arquivo nascentes --"
          #   return {status: 'success'}
          # rescue Exception => e
          #   Rails.logger.error "-- Requisição nascentes ERRO -- "+e.message
          #   return {status: 'failed', errors: e.message}
          # end
        end

      end
    end
  end
end