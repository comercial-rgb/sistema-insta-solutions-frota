class FaturaItem < ApplicationRecord
  self.table_name = 'fatura_itens'

  belongs_to :fatura
  belongs_to :order_service, optional: true
  belongs_to :order_service_proposal, optional: true

  TIPOS = %w[servico peca outro].freeze

  validates :valor, numericality: { greater_than_or_equal_to: 0 }
  validates :tipo, inclusion: { in: TIPOS }, allow_blank: true
end
