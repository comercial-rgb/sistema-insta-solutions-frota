class AddSemTabelaToReferencePrices < ActiveRecord::Migration[6.1]
  def change
    add_column :reference_prices, :sem_tabela, :boolean, default: false, null: false
  end
end
