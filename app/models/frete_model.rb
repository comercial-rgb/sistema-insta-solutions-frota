class FreteModel < ApplicationRecord

	def self.calculate_freight(cep_origem, cep_destino, peso, comprimento, largura, altura)
		frete = Correios::Frete::Calculador.new :cep_origem => cep_origem,
		:cep_destino => cep_destino,
		:peso => peso,
		:comprimento => comprimento,
		:largura => largura,
		:altura => altura

		begin
			return frete.calcular :sedex, :pac
		rescue Exception => e
			return []
		end
	end

end
