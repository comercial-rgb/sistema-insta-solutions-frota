class AddDescontoAndPagamentoToFaturas < ActiveRecord::Migration[7.1]
  def change
    add_column :faturas, :desconto, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :faturas, :data_pagamento, :date
    add_column :faturas, :pago_por_id, :bigint
    add_column :faturas, :sub_unit_id, :bigint

    add_index :faturas, :pago_por_id
    add_index :faturas, :sub_unit_id
    add_index :faturas, :data_vencimento
  end
end
