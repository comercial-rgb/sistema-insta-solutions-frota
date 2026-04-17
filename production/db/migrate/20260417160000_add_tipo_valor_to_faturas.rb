class AddTipoValorToFaturas < ActiveRecord::Migration[7.1]
  def change
    add_column :faturas, :tipo_valor, :string, default: 'bruto', null: false
  end
end
