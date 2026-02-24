class CreateCatalogoPecas < ActiveRecord::Migration[7.1]
  def change
    create_table :catalogo_pecas do |t|
      t.string :fornecedor, null: false, limit: 50
      t.string :marca, default: '', limit: 100
      t.string :veiculo, default: '', limit: 150
      t.string :modelo, default: '', limit: 150
      t.string :motor, default: '', limit: 100
      t.integer :ano_inicio
      t.integer :ano_fim
      t.string :grupo_produto, default: '', limit: 200
      t.string :produto, default: '', limit: 150
      t.string :observacao, default: '', limit: 300
      t.integer :pagina_origem
      t.string :arquivo_origem, limit: 255
      t.timestamps
    end

    add_index :catalogo_pecas, :fornecedor
    add_index :catalogo_pecas, :marca
    add_index :catalogo_pecas, [:veiculo, :modelo], name: 'idx_catalogo_veiculo_modelo'
    add_index :catalogo_pecas, :produto
    add_index :catalogo_pecas, :grupo_produto, length: 100
    add_index :catalogo_pecas, [:fornecedor, :marca, :veiculo, :modelo, :produto],
              name: 'idx_catalogo_unique_entry', length: { marca: 50, veiculo: 50, modelo: 50, produto: 80 }

    # Tabela de controle de arquivos PDF importados
    create_table :catalogo_pdf_imports do |t|
      t.string :filename, null: false
      t.string :fornecedor, null: false, limit: 50
      t.string :checksum, limit: 64
      t.integer :total_registros, default: 0
      t.integer :total_paginas, default: 0
      t.string :status, default: 'pendente', limit: 20
      t.text :log
      t.timestamps
    end

    add_index :catalogo_pdf_imports, :filename, unique: true
    add_index :catalogo_pdf_imports, :fornecedor
  end
end
