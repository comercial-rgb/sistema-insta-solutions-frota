class AddingNewBank < ActiveRecord::Migration[7.1]
  def change
    Bank.create(name: 'Banrisul', number: '041')
  end
end
