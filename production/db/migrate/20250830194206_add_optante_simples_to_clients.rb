class AddOptanteSimplesToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :optante_simples, :boolean, default: false
  end
end
