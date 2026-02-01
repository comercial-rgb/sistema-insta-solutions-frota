module Utils
  module Cep
    class CepService < BaseService
      attr_reader :cep

      def initialize(cep)
        @cep = cep.gsub(/[.,-]/, "")
      end

      def call
        return false if invalid?
        define_timeout
        get_cep
      end

      private

      def invalid?
        !(cep.length == 8 && !!(cep =~ /\A[-+]?[0-9]+\z/))
      end

      def define_timeout
        # Correios::CEP.configure do |config|
        #   config.request_timeout = 120
        # end
      end

      def get_cep
        begin
          data = nil
          # address # =>
          # {
          #   :address => 'Rua Fernando Amorim',
          #   :neighborhood => 'Cavaleiro',
          #   :city => 'Jaboatão dos Guararapes',
          #   :state => 'PE',
          #   :zipcode => '54250610',
          #   :complement => ''
          # }
          result = ViaCep::Address.new(cep)
          if !result.nil?
            if !result.address.nil? && !result.address.blank?
              data = {
                address: result.address,
                neighborhood: result.neighborhood,
                city: result.city,
                state: result.state,
                zipcode: result.cep,
                complement: ""
              }
            end
          end
          return data
        rescue Exception => e
          Rails.logger.error "-- get_cep --"
          Rails.logger.error e.message
          return nil
        end
      end

    end
  end
end
