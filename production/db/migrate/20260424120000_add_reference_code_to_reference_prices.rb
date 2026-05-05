class AddReferenceCodeToReferencePrices < ActiveRecord::Migration[6.1]
  def change
    add_column :reference_prices, :reference_code, :string
  end
end
