class AddTreinamentoApenasManualToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :treinamento_apenas_manual, :boolean, default: false, null: false
    add_column :users, :treinamento_apenas_manual_at, :datetime
  end
end
