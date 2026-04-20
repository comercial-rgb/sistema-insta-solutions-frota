class AddSplitNfFieldsToFaturas < ActiveRecord::Migration[7.1]
  def change
    add_column :faturas, :nota_fiscal_numero_pecas, :string
    add_column :faturas, :nota_fiscal_numero_servicos, :string
    add_column :faturas, :nota_fiscal_serie_pecas, :string
    add_column :faturas, :nota_fiscal_serie_servicos, :string
    add_column :faturas, :numero_pecas, :string
    add_column :faturas, :numero_servicos, :string

    add_index :faturas, :numero_pecas, unique: true
    add_index :faturas, :numero_servicos, unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE faturas
          SET numero_pecas = CONCAT(numero, '-P'),
              numero_servicos = CONCAT(numero, '-S')
          WHERE numero IS NOT NULL
            AND (numero_pecas IS NULL OR numero_servicos IS NULL)
        SQL
      end
    end
  end
end
