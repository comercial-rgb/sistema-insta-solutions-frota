class CatalogoPeca < ApplicationRecord
  self.table_name = 'catalogo_pecas'

  # Scopes de busca
  scope :by_fornecedor, ->(f) { where(fornecedor: f.upcase) if f.present? }
  scope :by_marca, ->(m) { where("LOWER(catalogo_pecas.marca) LIKE ?", "%#{m.downcase}%") if m.present? }
  scope :by_veiculo, ->(v) { where("LOWER(catalogo_pecas.veiculo) LIKE ?", "%#{v.downcase}%") if v.present? }
  scope :by_modelo, ->(m) { where("LOWER(catalogo_pecas.modelo) LIKE ?", "%#{m.downcase}%") if m.present? }
  scope :by_produto, ->(p) { where("LOWER(catalogo_pecas.produto) LIKE ?", "%#{p.downcase}%") if p.present? }
  scope :by_grupo_produto, ->(g) { where("LOWER(catalogo_pecas.grupo_produto) LIKE ?", "%#{g.downcase}%") if g.present? }
  scope :by_ano, ->(ano) {
    ano_int = ano.to_i
    where("(ano_inicio IS NULL OR ano_inicio <= ?) AND (ano_fim IS NULL OR ano_fim >= ?)", ano_int, ano_int) if ano.present? && ano_int > 0
  }
  scope :by_motor, ->(m) { where("LOWER(catalogo_pecas.motor) LIKE ?", "%#{m.downcase}%") if m.present? }

  # Busca inteligente a partir de um Vehicle do sistema
  def self.buscar_por_veiculo(vehicle, grupo_produto: nil, fornecedor: nil)
    return none unless vehicle.present?

    # Normaliza dados do veículo
    marca_veiculo = normalizar_marca(vehicle.brand)
    modelo_veiculo = vehicle.model.to_s.strip
    ano_veiculo = (vehicle.model_year || vehicle.year).to_s.strip
    motor_veiculo = vehicle.engine_displacement.to_s.strip

    query = by_marca(marca_veiculo)

    # Busca por modelo — tenta match exato primeiro, depois parcial
    if modelo_veiculo.present?
      palavras_modelo = modelo_veiculo.split(/[\s\/\-]+/).select { |p| p.length > 1 }
      if palavras_modelo.any?
        conditions = palavras_modelo.map { |p| "LOWER(catalogo_pecas.veiculo) LIKE ?" }
        values = palavras_modelo.map { |p| "%#{p.downcase}%" }
        query = query.where(conditions.join(" OR "), *values)
      end
    end

    # Filtra por ano se disponível
    if ano_veiculo.present?
      ano_int = ano_veiculo.gsub(/\D/, '')[0..3].to_i
      if ano_int > 1900
        query = query.by_ano(ano_int)
      end
    end

    # Filtra por motor se disponível (converte cc para litros)
    if motor_veiculo.present? && motor_veiculo.length > 2
      motor_litros = normalizar_motor(motor_veiculo)
      if motor_litros.present?
        query_com_motor = query.by_motor(motor_litros)
        # Soft filter: usa motor somente se não eliminar todos os resultados
        query = query_com_motor.exists? ? query_com_motor : query
      end
    end

    # Filtros opcionais
    query = query.by_grupo_produto(grupo_produto) if grupo_produto.present?
    query = query.by_fornecedor(fornecedor) if fornecedor.present?

    query.order(:grupo_produto, :produto).limit(200)
  end

  # Busca por texto livre (quando digitam no campo de peça)
  def self.buscar_por_texto(texto, vehicle: nil)
    return none if texto.blank?

    termos = texto.strip.split(/\s+/).select { |t| t.length > 1 }
    return none if termos.empty?

    # Busca em grupo_produto e produto
    conditions = termos.map { |_t| "(LOWER(catalogo_pecas.grupo_produto) LIKE ? OR LOWER(catalogo_pecas.produto) LIKE ?)" }
    values = termos.flat_map { |t| ["%#{t.downcase}%", "%#{t.downcase}%"] }

    query = where(conditions.join(" AND "), *values)

    # Se veículo fornecido, filtra por marca
    if vehicle.present? && vehicle.brand.present?
      marca = normalizar_marca(vehicle.brand)
      query = query.by_marca(marca)
    end

    query.select(:grupo_produto, :produto, :fornecedor, :marca, :veiculo, :modelo, :motor, :ano_inicio, :ano_fim, :observacao)
         .distinct
         .order(:grupo_produto, :produto)
         .limit(50)
  end

  # Busca referências do catálogo para uma peça + veículo
  # Retorna array de hashes: [{fornecedor, produto, grupo_produto, observacao}]
  # Agrupa por fornecedor para mostrar códigos de cada marca
  def self.buscar_referencias(nome_peca, vehicle: nil)
    return [] if nome_peca.blank?

    nome_limpo = I18n.transliterate(nome_peca.to_s.strip.downcase)
    termos = nome_limpo.split(/\s+/).select { |t| t.length > 2 }
    return [] if termos.empty?

    # Busca por grupo_produto que contenha os termos
    conditions = termos.map { |_| "LOWER(grupo_produto) LIKE ?" }
    values = termos.map { |t| "%#{t}%" }
    query = where(conditions.join(" AND "), *values)

    # Filtra por veículo se disponível
    if vehicle.present? && vehicle.brand.present?
      marca = normalizar_marca(vehicle.brand)
      query = query.by_marca(marca)

      if vehicle.model.present?
        palavras = vehicle.model.split(/[\s\/\-]+/).select { |p| p.length > 1 }
        if palavras.any?
          conds = palavras.map { |_| "LOWER(veiculo) LIKE ?" }
          vals = palavras.map { |p| "%#{p.downcase}%" }
          query = query.where(conds.join(" OR "), *vals)
        end
      end

      ano = (vehicle.model_year || vehicle.year).to_s.gsub(/\D/, '')[0..3].to_i
      query = query.by_ano(ano) if ano > 1900
    end

    query
      .select(:fornecedor, :produto, :grupo_produto, :observacao)
      .distinct
      .order(:fornecedor, :produto)
      .limit(30)
      .map { |r| { fornecedor: r.fornecedor, produto: r.produto, grupo_produto: r.grupo_produto, observacao: r.observacao } }
  end

  # Formata referências como string: "FRASLE: PD/1234 | FREMAX: BD-5560"
  def self.formatar_referencias(nome_peca, vehicle: nil)
    refs = buscar_referencias(nome_peca, vehicle: vehicle)
    return '' if refs.empty?

    refs.map { |r| "#{r[:fornecedor]}: #{r[:produto]}" }.uniq.join(' | ')
  end

  # Normalização inteligente: encontra o nome mais específico do catálogo
  # Usa scoring por sobreposição EXATA de palavras (sem substring)
  # Previne falsos positivos como "FILTRO DE OLEO" → "Reservatório de óleo"
  # Cache de grupos em memória para performance (172k registros → ~129 grupos distintos)
  def self.normalizar_nome_inteligente(nome, grupos_cache: nil)
    return nome if nome.blank?

    nome_limpo = I18n.transliterate(nome.to_s.strip.downcase).gsub(/[^a-z0-9\s]/, ' ').squish
    termos = nome_limpo.split(/\s+/).select { |t| t.length > 2 }
    return nome if termos.empty?

    # Usa cache ou carrega os grupos de produto distintos (feito 1x)
    candidatos = grupos_cache || grupos_produto_cache
    return nome if candidatos.empty?

    # Palavra única: exige match exato ou quase exato com algum grupo
    if termos.size == 1
      exato = candidatos.find { |_grupo, info| info[:norm] == nome_limpo }
      return exato[0] if exato

      # Tenta match por similaridade de palavra única (prefixo de 5+ chars)
      melhor = candidatos.select { |_grupo, info|
        info[:termos].size == 1 && termos_similares?(termos[0], info[:termos][0])
      }.max_by { |grupo, _| grupo.length }
      return melhor[0] if melhor

      return nome
    end

    # Multi-termos: scoring com match EXATO de palavras (sem substring)
    melhor_score = 0
    melhor_nome = nil

    candidatos.each do |grupo, grupo_info|
      grupo_termos = grupo_info[:termos]
      next if grupo_termos.empty?

      # Match exato de String completa
      if grupo_info[:norm] == nome_limpo
        melhor_score = 1.5
        melhor_nome = grupo
        break
      end

      # Conta termos do input encontrados no candidato (match por similaridade de palavra)
      matches_in = termos.count { |t| grupo_termos.any? { |gt| termos_similares?(t, gt) } }
      # Conta termos do candidato encontrados no input
      matches_out = grupo_termos.count { |gt| termos.any? { |t| termos_similares?(t, gt) } }

      # Score = MÍNIMO das duas direções (não média!)
      # Isso exige que AMBOS os lados tenham boa cobertura
      # Ex: "FILTRO DE OLEO" vs "Reservatório de óleo" → in=1/2=0.5, out=1/2=0.5 → min=0.5 → REJEITADO
      score_in = matches_in.to_f / termos.size
      score_out = grupo_termos.any? ? matches_out.to_f / grupo_termos.size : 0
      score = [score_in, score_out].min

      # Prefere nomes mais longos (mais específicos) em caso de empate
      if score > melhor_score || (score == melhor_score && melhor_nome && grupo.length > melhor_nome.length)
        melhor_score = score
        melhor_nome = grupo
      end
    end

    # Threshold: pelo menos 70% de match em AMBAS as direções
    # Isso garante que a maioria dos termos significativos coincidam
    # Ex: "oleo caixa cambio" vs "Terminal da caixa de câmbio" → 2/3=0.67 → REJEITADO
    if melhor_score >= 0.7 && melhor_nome.present?
      melhor_nome
    else
      nome
    end
  end

  # Verifica se dois termos são similares (variações da mesma palavra)
  # Usa comparação por prefixo para lidar com flexões do português
  # Ex: estabilizador/estabilizadora, dianteiro/dianteira, freio/freios
  def self.termos_similares?(t1, t2)
    return true if t1 == t2
    return false if t1.length < 4 || t2.length < 4

    menor, maior = [t1, t2].sort_by(&:length)

    # Diferença máxima de 3 caracteres (cobre plurais, gênero, etc.)
    return false if (maior.length - menor.length) > 3

    # O maior deve começar com o menor inteiro (prefixo compartilhado)
    maior.start_with?(menor)
  end

  # Cache de grupos de produto com termos pré-processados (carregado 1x por processo)
  def self.grupos_produto_cache
    @grupos_produto_cache ||= begin
      distinct.pluck(:grupo_produto)
        .reject(&:blank?)
        .map { |g| g.gsub("\n", " ").strip }
        .uniq
        .each_with_object({}) do |grupo, hash|
          norm = I18n.transliterate(grupo.downcase).gsub(/[^a-z0-9\s]/, ' ').squish
          termos = norm.split(/\s+/).select { |t| t.length > 2 }
          hash[grupo] = { norm: norm, termos: termos }
        end
    end
  end

  # Limpa cache (usar após reimportação)
  def self.limpar_cache!
    @grupos_produto_cache = nil
  end

  # Lista fornecedores disponíveis no catálogo
  def self.fornecedores_disponiveis
    distinct.pluck(:fornecedor).sort
  end

  # Lista grupos de produto disponíveis
  def self.grupos_produto_disponiveis
    distinct.pluck(:grupo_produto).reject(&:blank?).sort
  end

  private

  # Normaliza marca do veículo para match com catálogo
  def self.normalizar_marca(marca)
    return '' if marca.blank?

    mapa = {
      'GM' => 'CHEVROLET', 'GENERAL MOTORS' => 'CHEVROLET',
      'VW' => 'VOLKSWAGEN', 'VOLKS' => 'VOLKSWAGEN',
      'MB' => 'MERCEDES-BENZ', 'MERCEDES' => 'MERCEDES-BENZ',
      'LAND-ROVER' => 'LAND ROVER',
      'MERCEDES BENZ' => 'MERCEDES-BENZ',
    }

    normalizada = I18n.transliterate(marca.to_s.strip.upcase)
    mapa[normalizada] || normalizada
  end

  # Normaliza motor: converte cilindrada em cc (ex: "2000") para litros (ex: "2.0")
  # Catálogo usa formato "2.0 L 8V SOHC L4", veículo armazena "2000" (cc)
  def self.normalizar_motor(motor_str)
    return nil if motor_str.blank?

    # Se já contém ponto, já está em litros (ex: "2.0")
    return motor_str if motor_str.include?('.')

    # Extrai apenas dígitos
    cc = motor_str.to_s.gsub(/\D/, '').to_i
    return nil if cc == 0

    if cc >= 500  # Valor em cc (ex: 2000, 1598, 1800)
      litros = (cc / 1000.0).round(1)
      format('%.1f', litros)
    else
      motor_str  # Valor pequeno, pode já ser litros sem ponto
    end
  end
end
