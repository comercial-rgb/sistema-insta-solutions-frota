class DataBank < ApplicationRecord
	belongs_to :ownertable, :polymorphic => true, optional: true
	belongs_to :bank, optional: true
	belongs_to :data_bank_type, optional: true

	# validates_presence_of :bank_id, :data_bank_type_id, :agency, :account

	def as_json(options = {})
		{
			:id => self.id,
			:bank_id => self.bank_id,
			:bank => self.bank,
			:data_bank_type_id => self.data_bank_type_id,
			:data_bank_type => self.data_bank_type,
			:agency => self.agency,
			:account => self.account,
			:operation => self.operation,
			:cpf_cnpj => self.cpf_cnpj,
			:pix => self.pix
		}
	end

end
