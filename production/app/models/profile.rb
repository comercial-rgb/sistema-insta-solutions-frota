class Profile < ActiveRecord::Base
	ADMIN = "Administrador"
	USER = "Usuário"
	CLIENT = "Cliente"
	MANAGER = "Gestor"
	ADDITIONAL = "Adicional"
	PROVIDER = "Fornecedor"

	ADMIN_ID = 1
	USER_ID = 2
	CLIENT_ID = 3
	MANAGER_ID = 4
	ADDITIONAL_ID = 5
	PROVIDER_ID = 6

	has_many :users

	has_and_belongs_to_many :orientation_manuals, dependent: :destroy

	validates_presence_of :name

	scope :to_notification, -> { where(id: [MANAGER_ID, ADDITIONAL_ID, PROVIDER_ID]) }

	scope :to_orientation_manual, -> { where(id: [MANAGER_ID, ADDITIONAL_ID, PROVIDER_ID]) }

	def as_json(options = {})
		{
			:id => self.id,
			:name => self.name
		}
	end

	def admin?
		self.id == Profile::ADMIN_ID
	end

	def user?
		self.id == Profile::USER_ID
	end

	def client?
		self.id == Profile::CLIENT_ID
	end

	def manager?
		self.id == Profile::MANAGER_ID
	end

	def additional?
		self.id == Profile::ADDITIONAL_ID
	end

	def provider?
		self.id == Profile::PROVIDER_ID
	end

	def to_s
		name
	end

end
