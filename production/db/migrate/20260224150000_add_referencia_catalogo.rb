class AddReferenciaCatalogo < ActiveRecord::Migration[7.1]
  def change
    # Campo para armazenar referências do catálogo PDF (ex: "FRASLE: PD/1234 | FREMAX: BD-5560")
    add_column :provider_service_temps, :referencia_catalogo, :string, limit: 500
    add_column :order_service_proposal_items, :referencia_catalogo, :string, limit: 500
  end
end
