class CreateFaturasAndFaturaItens < ActiveRecord::Migration[7.1]
  def change
    create_table :faturas do |t|
      t.string   :numero,               null: false
      t.references :provider, foreign_key: { to_table: :users }
      t.references :cost_center, foreign_key: true
      t.references :contract, foreign_key: true
      t.date     :data_emissao,         null: false
      t.date     :data_envio_empresa
      t.date     :data_recebimento
      t.date     :data_vencimento
      t.integer  :prazo_recebimento,    default: 30
      t.string   :status,               default: 'aberta', null: false
      t.decimal  :valor_bruto,          precision: 15, scale: 2, default: 0
      t.decimal  :valor_liquido,        precision: 15, scale: 2, default: 0
      t.decimal  :total_retencoes,      precision: 15, scale: 2, default: 0
      t.decimal  :taxa_administracao,   precision: 15, scale: 2, default: 0
      t.decimal  :valor_final,          precision: 15, scale: 2, default: 0
      t.integer  :total_itens,          default: 0
      t.decimal  :ir_percentual,        precision: 5, scale: 2, default: 0
      t.decimal  :pis_percentual,       precision: 5, scale: 2, default: 0
      t.decimal  :cofins_percentual,    precision: 5, scale: 2, default: 0
      t.decimal  :csll_percentual,      precision: 5, scale: 2, default: 0
      t.string   :nota_fiscal_numero
      t.string   :nota_fiscal_serie
      t.text     :observacoes
      t.text     :admin_observacoes

      t.timestamps
    end

    add_index :faturas, :numero, unique: true
    add_index :faturas, :status
    add_index :faturas, :data_emissao

    create_table :fatura_itens do |t|
      t.references :fatura, null: false, foreign_key: true
      t.references :order_service, foreign_key: true
      t.references :order_service_proposal, foreign_key: true
      t.string   :descricao
      t.string   :tipo,                default: 'servico'
      t.decimal  :valor,               precision: 15, scale: 2, default: 0
      t.decimal  :quantidade,          precision: 10, scale: 3, default: 1
      t.string   :veiculo_placa
      t.string   :centro_custo_nome

      t.timestamps
    end

    add_index :fatura_itens, :tipo
  end
end
