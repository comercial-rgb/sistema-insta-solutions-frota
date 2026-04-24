class AddObservacoesToFaturaItens < ActiveRecord::Migration[6.1]
  def change
    add_column :fatura_itens, :observacoes, :text
  end
end
