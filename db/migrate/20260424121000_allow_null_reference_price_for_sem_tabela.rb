class AllowNullReferencePriceForSemTabela < ActiveRecord::Migration[6.1]
  def change
    change_column_null :reference_prices, :reference_price, true
  end
end
