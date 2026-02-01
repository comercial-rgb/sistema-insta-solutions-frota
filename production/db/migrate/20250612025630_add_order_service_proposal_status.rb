class AddOrderServiceProposalStatus < ActiveRecord::Migration[7.1]
  def change
    OrderServiceProposalStatus.create(name: 'Em cadastro')
  end
end
