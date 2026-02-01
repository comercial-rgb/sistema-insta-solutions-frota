class AddNewBank < ActiveRecord::Migration[7.1]
  def change
    Bank.create(number: '748', name: "Sicredi")
  end
end
