class Fatura < ApplicationRecord
  belongs_to :provider, class_name: 'User', optional: true
  belongs_to :cost_center, optional: true
  belongs_to :contract, optional: true

  has_many :fatura_itens, dependent: :destroy

  STATUSES = %w[aberta enviada paga cancelada].freeze

  validates :numero, presence: true, uniqueness: true
  validates :data_emissao, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :abertas,    -> { where(status: 'aberta') }
  scope :enviadas,   -> { where(status: 'enviada') }
  scope :pagas,      -> { where(status: 'paga') }
  scope :canceladas, -> { where(status: 'cancelada') }
  scope :vencidas,   -> { where(status: %w[aberta enviada]).where('data_vencimento < ?', Date.current) }

  def vencida?
    %w[aberta enviada].include?(status) && data_vencimento.present? && data_vencimento < Date.current
  end

  def calcular_retencoes!
    base = valor_bruto || 0
    ir   = base * (ir_percentual || 0) / 100
    pis  = base * (pis_percentual || 0) / 100
    cof  = base * (cofins_percentual || 0) / 100
    csll = base * (csll_percentual || 0) / 100
    self.total_retencoes = ir + pis + cof + csll
    self.valor_liquido   = base - total_retencoes
    self.valor_final     = valor_liquido - (taxa_administracao || 0)
  end

  def self.gerar_numero
    ultimo = order(created_at: :desc).first
    seq = ultimo ? ultimo.numero.to_s.scan(/\d+/).last.to_i + 1 : 1
    "FAT-#{Date.current.strftime('%Y%m')}-#{seq.to_s.rjust(4, '0')}"
  end
end
