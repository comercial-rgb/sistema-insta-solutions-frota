module Utils
  module Catalogo
    class SearchService < BaseService
      attr_reader :results, :vehicle, :grupo_produto, :fornecedor, :texto

      def initialize(params = {})
        @errors = { base: [] }
        @results = []
        @vehicle = params[:vehicle]
        @vehicle_id = params[:vehicle_id]
        @grupo_produto = params[:grupo_produto]
        @fornecedor = params[:fornecedor]
        @texto = params[:texto]
      end

      def call
        load_vehicle if @vehicle_id.present? && @vehicle.nil?

        if @texto.present?
          @results = buscar_por_texto
        elsif @vehicle.present?
          @results = buscar_por_veiculo
        else
          @errors[:base] << "Informe um veículo ou texto para busca"
        end

        self
      end

      private

      def load_vehicle
        @vehicle = Vehicle.find_by(id: @vehicle_id)
        @errors[:base] << "Veículo não encontrado" unless @vehicle
      end

      def buscar_por_veiculo
        CatalogoPeca.buscar_por_veiculo(
          @vehicle,
          grupo_produto: @grupo_produto,
          fornecedor: @fornecedor
        )
      end

      def buscar_por_texto
        CatalogoPeca.buscar_por_texto(@texto, vehicle: @vehicle)
      end
    end
  end
end
