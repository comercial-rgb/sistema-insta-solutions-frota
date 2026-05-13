class AddPartialPaymentToFaturas < ActiveRecord::Migration[7.1]
  def change
    change_table :faturas, bulk: true do |t|
      t.string  :status_pecas,              default: 'aberta'
      t.string  :status_servicos,           default: 'aberta'
      t.decimal :valor_bruto_pecas,         precision: 15, scale: 2, default: 0
      t.decimal :valor_bruto_servicos,      precision: 15, scale: 2, default: 0
      t.date    :data_pagamento_pecas
      t.date    :data_pagamento_servicos
    end
  end
end
