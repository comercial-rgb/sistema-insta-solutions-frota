class AddNewOrderServiceStatus < ActiveRecord::Migration[7.1]
  def change
    # Status "Em cadastro" agora é criado pelo seed com IDs fixos
    # Mantido para compatibilidade com migrações antigas
    OrderServiceStatus.find_or_create_by(name: 'Em cadastro')
  end
end
