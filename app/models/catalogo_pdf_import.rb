class CatalogoPdfImport < ApplicationRecord
  self.table_name = 'catalogo_pdf_imports'

  validates :filename, presence: true, uniqueness: true
  validates :fornecedor, presence: true

  scope :pendentes, -> { where(status: 'pendente') }
  scope :processados, -> { where(status: 'processado') }
  scope :com_erro, -> { where(status: 'erro') }

  def processado?
    status == 'processado'
  end

  def marcar_processado!(total_registros:, total_paginas:, log: nil)
    update!(
      status: 'processado',
      total_registros: total_registros,
      total_paginas: total_paginas,
      log: log
    )
  end

  def marcar_erro!(mensagem)
    update!(status: 'erro', log: mensagem)
  end
end
