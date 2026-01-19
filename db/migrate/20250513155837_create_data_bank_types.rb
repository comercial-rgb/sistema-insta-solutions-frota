class CreateDataBankTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :data_bank_types do |t|
      t.string :name

      t.timestamps
    end
    datetime_now = DateTime.now
    array_DataBankType = [
      {name: "Corrente", created_at: datetime_now, updated_at: datetime_now},
      {name: "Poupança", created_at: datetime_now, updated_at: datetime_now},
      {name: "Salário", created_at: datetime_now, updated_at: datetime_now},
    ]
    DataBankType.insert_all(array_DataBankType)
  end
end
