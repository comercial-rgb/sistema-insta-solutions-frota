class CatalogoPecasController < ApplicationController
  before_action :authenticate_user

  # GET /catalogo_pecas/search?vehicle_id=X&texto=Y&grupo_produto=Z&fornecedor=W
  def search
    service = Utils::Catalogo::SearchService.new(
      vehicle_id: params[:vehicle_id],
      texto: params[:texto],
      grupo_produto: params[:grupo_produto],
      fornecedor: params[:fornecedor]
    )
    service.call

    respond_to do |format|
      format.json do
        if service.success?
          render json: {
            success: true,
            results: service.results.map { |r| serialize_catalogo(r) },
            total: service.results.size
          }
        else
          render json: { success: false, errors: service.errors[:base] }, status: :unprocessable_entity
        end
      end
      format.html do
        @results = service.results
        @vehicle = service.vehicle
        @fornecedores = CatalogoPeca.fornecedores_disponiveis
        @grupos = CatalogoPeca.grupos_produto_disponiveis
      end
    end
  end

  # GET /catalogo_pecas/sugestoes?vehicle_id=X&nome_peca=Y
  # Usado pelo JS do formulário de proposta para sugerir peças do catálogo
  def sugestoes
    vehicle = Vehicle.find_by(id: params[:vehicle_id])
    nome_peca = params[:nome_peca].to_s.strip

    resultados = []

    if nome_peca.present?
      resultados = CatalogoPeca.buscar_por_texto(nome_peca, vehicle: vehicle)
    elsif vehicle.present?
      resultados = CatalogoPeca.buscar_por_veiculo(vehicle).limit(30)
    end

    render json: resultados.map { |r| serialize_catalogo(r) }
  end

  # GET /catalogo_pecas/fornecedores
  def fornecedores
    render json: CatalogoPeca.fornecedores_disponiveis
  end

  # GET /catalogo_pecas/grupos
  def grupos
    render json: CatalogoPeca.grupos_produto_disponiveis
  end

  # GET /catalogo_pecas/stats
  def stats
    render json: {
      total_registros: CatalogoPeca.count,
      fornecedores: CatalogoPeca.group(:fornecedor).count,
      pdfs_importados: CatalogoPdfImport.processados.count,
      pdfs_pendentes: CatalogoPdfImport.pendentes.count,
      ultimo_import: CatalogoPdfImport.processados.order(updated_at: :desc).first&.updated_at
    }
  end

  private

  def serialize_catalogo(r)
    {
      fornecedor: r.fornecedor,
      marca: r.marca,
      veiculo: r.veiculo,
      modelo: r.modelo,
      motor: r.motor,
      ano_inicio: r.ano_inicio,
      ano_fim: r.ano_fim,
      grupo_produto: r.grupo_produto,
      produto: r.produto,
      observacao: r.observacao,
      # Nome formatado para exibir no select
      nome_completo: "#{r.grupo_produto} - #{r.produto} (#{r.fornecedor})",
      # Nome padronizado para usar como nome do Service
      nome_padrao: r.grupo_produto.to_s.gsub("\n", " ").strip
    }
  end
end
