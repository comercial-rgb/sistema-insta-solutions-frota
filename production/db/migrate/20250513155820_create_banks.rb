class CreateBanks < ActiveRecord::Migration[7.1]
  def change
    create_table :banks do |t|
      t.string :number
      t.string :name

      t.timestamps
    end
    datetime_now = DateTime.now
    array_Bank = [
      {number: "001", name: "Banco do Brasil S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "341", name: "Banco Itaú S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "033", name: "Banco Santander (Brasil) S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "356", name: "Banco Real S.A. (antigo)", created_at: datetime_now, updated_at: datetime_now},
      {number: "652", name: "Itaú Unibanco Holding S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "237", name: "Banco Bradesco S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "745", name: "Banco Citibank S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "399", name: "HSBC Bank Brasil S.A. – Banco Múltiplo", created_at: datetime_now, updated_at: datetime_now},
      {number: "104", name: "Caixa Econômica Federal", created_at: datetime_now, updated_at: datetime_now},
      {number: "389", name: "Banco Mercantil do Brasil S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "453", name: "Banco Rural S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "422", name: "Banco Safra S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "633", name: "Banco Rendimento S.A.", created_at: datetime_now, updated_at: datetime_now},
      {number: "756", name: "Sicoob", created_at: datetime_now, updated_at: datetime_now},
      {number: "077", name: "Banco Inter", created_at: datetime_now, updated_at: datetime_now},
      {number: "237", name: "Banco Next", created_at: datetime_now, updated_at: datetime_now},
      {number: "121", name: "Agibank", created_at: datetime_now, updated_at: datetime_now},
      {number: "260", name: "Nuconta (Nubank)", created_at: datetime_now, updated_at: datetime_now},
      {number: "033", name: "Superdigital", created_at: datetime_now, updated_at: datetime_now},
      {number: "637", name: "Sofisa Direto", created_at: datetime_now, updated_at: datetime_now},
      {number: "", name: "Pag!", created_at: datetime_now, updated_at: datetime_now},
      {number: "290", name: "PagBank", created_at: datetime_now, updated_at: datetime_now},
      {number: "735", name: "Banco Neon", created_at: datetime_now, updated_at: datetime_now},
      {number: "655", name: "Votorantim", created_at: datetime_now, updated_at: datetime_now},
    ]
    Bank.insert_all(array_Bank)
  end
end
