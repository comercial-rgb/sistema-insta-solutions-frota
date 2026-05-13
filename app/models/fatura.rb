class Fatura < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id', optional: true
  belongs_to :cost_center, optional: true
  belongs_to :contract, optional: true
  belongs_to :sub_unit, optional: true
  belongs_to :pago_por, class_name: 'User', foreign_key: 'pago_por_id', optional: true

  has_many :fatura_itens, class_name: 'FaturaItem', dependent: :destroy

  has_one_attached :nota_fiscal_pecas_file
  has_one_attached :nota_fiscal_servicos_file
  has_one_attached :nota_fiscal_consolidada_file
  validates :nota_fiscal_pecas_file,       safe_file: { profile: :invoice }, if: -> { nota_fiscal_pecas_file.attached? }
  validates :nota_fiscal_servicos_file,    safe_file: { profile: :invoice }, if: -> { nota_fiscal_servicos_file.attached? }
  validates :nota_fiscal_consolidada_file, safe_file: { profile: :invoice }, if: -> { nota_fiscal_consolidada_file.attached? }

  STATUSES      = %w[aberta enviada paga cancelada].freeze
  TIPO_STATUSES = %w[aberta paga nao_aplicavel].freeze

  validates :numero, presence: true, uniqueness: true
  validates :data_emissao, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :status_pecas,    inclusion: { in: TIPO_STATUSES }, allow_nil: true
  validates :status_servicos, inclusion: { in: TIPO_STATUSES }, allow_nil: true

  before_validation :ensure_split_numeros

  scope :abertas,    -> { where(status: 'aberta') }
  scope :enviadas,   -> { where(status: 'enviada') }
  scope :pagas,      -> { where(status: 'paga') }
  scope :canceladas, -> { where(status: 'cancelada') }
  scope :vencidas,   -> { where(status: %w[aberta enviada]).where('data_vencimento < ?', Date.current) }

  def vencida?
    %w[aberta enviada].include?(status) && data_vencimento.present? && data_vencimento < Date.current
  end

  def dias_vencida
    return 0 unless vencida?
    (Date.current - data_vencimento).to_i
  end

  def calcular_retencoes!
    bruto = valor_bruto.to_f
    desc = desconto.to_f
    # Com tipo_valor "bruto", retenções incidem sobre o valor bruto (sem abater desconto).
    # Com "liquido", a base é bruto − desconto (valor após desconto do contrato).
    base_tributavel = tipo_valor.to_s == 'liquido' ? (bruto - desc) : bruto
    ir   = base_tributavel * (ir_percentual || 0) / 100
    pis  = base_tributavel * (pis_percentual || 0) / 100
    cof  = base_tributavel * (cofins_percentual || 0) / 100
    csll = base_tributavel * (csll_percentual || 0) / 100
    self.total_retencoes = ir + pis + cof + csll
    self.valor_liquido   = base_tributavel - total_retencoes
    self.valor_final     = valor_liquido - (taxa_administracao || 0)
  end

  def self.gerar_numero
    ultimo = order(created_at: :desc).first
    seq = ultimo ? ultimo.numero.to_s.scan(/\d+/).last.to_i + 1 : 1
    "FAT-#{Date.current.strftime('%Y%m')}-#{seq.to_s.rjust(4, '0')}"
  end

  def self.gerar_numero_tipo(tipo)
    campo  = tipo == :pecas ? :numero_pecas : :numero_servicos
    sufixo = tipo == :pecas ? 'P' : 'S'
    ultimo = where.not(campo => nil).order("#{campo} DESC").first
    seq = ultimo ? ultimo.send(campo).to_s.scan(/\d+/).last.to_i + 1 : 1
    "FAT-#{Date.current.strftime('%Y%m')}-#{seq.to_s.rjust(4, '0')}-#{sufixo}"
  end

  # Retorna o CNPJ correto para faturamento:
  # Prioridade: invoice_cnpj do centro de custo → cnpj do cliente
  def cnpj_faturamento
    cost_center&.invoice_cnpj.presence || client&.cnpj
  end

  # Razão social correta para faturamento:
  # Prioridade: invoice_name do centro de custo → nome do cliente
  def nome_faturamento
    cost_center&.invoice_name.presence ||
      client&.social_name.presence ||
      client&.fantasy_name.presence ||
      client&.name
  end

  def tem_pecas?
    valor_bruto_pecas.to_f > 0
  end

  def tem_servicos?
    valor_bruto_servicos.to_f > 0
  end

  # Baixa parcial por tipo. Marca a fatura inteira como 'paga' quando ambos os tipos
  # estiverem quitados (ou marcados como não aplicável).
  def marcar_tipo_pago!(tipo, data: Date.current, user_id: nil)
    caso = tipo.to_s
    raise ArgumentError, "tipo inválido: #{tipo}" unless %w[pecas servicos ambos].include?(caso)

    attrs = {}
    if %w[pecas ambos].include?(caso)
      attrs[:status_pecas]          = 'paga'
      attrs[:data_pagamento_pecas]  = data
    end
    if %w[servicos ambos].include?(caso)
      attrs[:status_servicos]           = 'paga'
      attrs[:data_pagamento_servicos]   = data
    end

    # Marca a fatura inteira como paga se ambos os tipos estiverem quitados
    status_p = attrs[:status_pecas]    || status_pecas
    status_s = attrs[:status_servicos] || status_servicos
    if [status_p, status_s].all? { |s| %w[paga nao_aplicavel].include?(s) }
      attrs[:status]          = 'paga'
      attrs[:data_pagamento]  = data
      attrs[:pago_por_id]     = user_id if user_id
    end

    update!(attrs)
  end

  private

  def ensure_split_numeros
    return if numero.blank?
    self.numero_pecas    = self.class.gerar_numero_tipo(:pecas)    if numero_pecas.blank?
    self.numero_servicos = self.class.gerar_numero_tipo(:servicos) if numero_servicos.blank?
  end
end
