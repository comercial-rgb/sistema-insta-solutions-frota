class Fatura < ApplicationRecord
  belongs_to :client, class_name: 'User', foreign_key: 'client_id', optional: true
  belongs_to :cost_center, optional: true
  belongs_to :contract, optional: true
  belongs_to :sub_unit, optional: true
  belongs_to :pago_por, class_name: 'User', foreign_key: 'pago_por_id', optional: true

  has_many :fatura_itens, class_name: 'FaturaItem', dependent: :destroy

  has_one_attached :nota_fiscal_pecas_file
  has_one_attached :nota_fiscal_servicos_file

  STATUSES = %w[aberta enviada paga cancelada].freeze

  validates :numero, presence: true, uniqueness: true
  validates :data_emissao, presence: true
  validates :status, inclusion: { in: STATUSES }

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
    base = valor_bruto || 0
    desc = desconto || 0
    base_liquida = base - desc
    ir   = base_liquida * (ir_percentual || 0) / 100
    pis  = base_liquida * (pis_percentual || 0) / 100
    cof  = base_liquida * (cofins_percentual || 0) / 100
    csll = base_liquida * (csll_percentual || 0) / 100
    self.total_retencoes = ir + pis + cof + csll
    self.valor_liquido   = base_liquida - total_retencoes
    self.valor_final     = valor_liquido - (taxa_administracao || 0)
  end

  def self.gerar_numero
    ultimo = order(created_at: :desc).first
    seq = ultimo ? ultimo.numero.to_s.scan(/\d+/).last.to_i + 1 : 1
    "FAT-#{Date.current.strftime('%Y%m')}-#{seq.to_s.rjust(4, '0')}"
  end

  private

  def ensure_split_numeros
    return if numero.blank?

    self.numero_pecas = "#{numero}-P" if numero_pecas.blank?
    self.numero_servicos = "#{numero}-S" if numero_servicos.blank?
  end
end
