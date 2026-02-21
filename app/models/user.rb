class User < ActiveRecord::Base
	acts_as_reader
	paginates_per 24
	after_initialize :default_values
	before_validation :insert_profile_image

	ADMIN_FIRST_ID = 1

	default_scope {
		includes(:profile, :person_type, :sex, :user_status)
	}

	attr_accessor :skip_validate_password,
	:seed, :edit_pass, :profile_image_url,
	:new_user, :current_password, :page_title, :skip_accept_therm,
	:profile_image_file

	belongs_to :profile, optional: true
	belongs_to :person_type, optional: true
	belongs_to :sex, optional: true
	belongs_to :user_status, optional: true

	belongs_to :client, class_name: "User", optional: true

	belongs_to :state, optional: true
	belongs_to :city, optional: true

	has_one :attachment, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :attachment

	has_one :address, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :address

	has_many :addresses, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :addresses, :reject_if => :all_blank

	has_many :attachments, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :attachments, :reject_if => :all_blank

	has_many :person_contacts, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :person_contacts, :reject_if => proc { |attrs| attrs[:name].blank? }

	has_one :data_bank, as: :ownertable, validate: false, dependent: :destroy
	accepts_nested_attributes_for :data_bank, :reject_if => :all_blank

	has_and_belongs_to_many :provider_service_types, dependent: :destroy

	# This association represents cost centers where the user is the client
	has_many :client_cost_centers, class_name: 'CostCenter', foreign_key: 'client_id', dependent: :destroy

	# This association represents cost centers where the user is associated via a join table
	has_and_belongs_to_many :associated_cost_centers, class_name: 'CostCenter', join_table: 'cost_centers_users', dependent: :destroy

	# This association represents cost centers where the user is associated via a join table
	has_and_belongs_to_many :associated_sub_units, class_name: 'SubUnit', join_table: 'sub_units_users', dependent: :destroy

	has_many :vinculed_users, class_name: 'User', foreign_key: 'client_id', dependent: :destroy

	has_many :vehicles, foreign_key: 'client_id', dependent: :destroy

	has_many :contracts, foreign_key: 'client_id', dependent: :destroy

	# Estados para recebimento de propostas
	has_and_belongs_to_many :states, dependent: :destroy

	has_and_belongs_to_many :rejected_order_services,
							class_name: 'OrderService',
							join_table: :rejected_order_services_providers,
							association_foreign_key: :order_service_id,
							foreign_key: :provider_id,
							dependent: :destroy

	# OSs direcionadas especificamente a este fornecedor
	has_and_belongs_to_many :directed_order_services,
							class_name: 'OrderService',
							join_table: :order_service_directed_providers,
							association_foreign_key: :order_service_id,
							foreign_key: :provider_id

	# <%= collection_check_boxes(:user, :example_ids, Example.order(:name), :id, :name) do |b| %>
	# <div class="col-12 mt-2">
	#     <%= b.label do %>
	#             <%= b.check_box(class: "") %>
	#             <%= b.text %>
	#     <% end %>
	# </div>
	# <% end %>
	#
	# <%= model.collection_check_boxes(:{table_ids}, {collection}, :id, :name) do |b| %>
	# 	<div class="col-12 mt-1">
	# 		<%= b.label do %>
	# 		<%= b.check_box(inline_label: true, legend_tag: false) %>
	# 		<%= b.text %>
	# 		<% end %>
	# 	</div>
	# <% end %>
	# has_and_belongs_to_many :examples


	# <label><%= Offer.human_attribute_name(:offer_color_id) %></label>
	#    <%= collection_radio_buttons(:offer, :offer_color_id, OfferColor.all, :id, :name) do |b| %>
	#        <div class="col-12 mt-2" style="background-color: <%= b.object.color %>;">
	#            <%= b.label do %>
	#                <%= b.radio_button(class: "") %>
	#                <span style="color: <%= b.object.background_color %>"><%= b.text %></span>
	#            <% end %>
	#        </div>
	#    <% end %>
	#
	# <%= model.collection_radio_buttons(:{table_ids}, {collection}, :id, :name) do |b| %>
	# 	<div class="col-12 mt-1">
	# 		<%= b.label do %>
	# 		<%= b.radio_button(inline_label: true, legend_tag: false) %>
	# 		<%= b.text %>
	# 		<% end %>
	# 	</div>
	# <% end %>
	# belongs_to :example

	has_secure_password
	validates_presence_of :password, if: Proc.new { |user| user.skip_validate_password != true }

	validates_presence_of :profile_id, :name, :email, if: Proc.new { |user| user.skip_validate_password != true }

	validate :name_is_less_than_2, if: Proc.new { |user| user.seed != true && user.skip_validate_password != true }

	validates_presence_of :current_plan_id, if: Proc.new { |user| user.user? }

	validates_presence_of :client_id, if: Proc.new { |user| user.manager? || user.additional? }

	# Exemplo self relation
	# belongs_to :parent, :class_name => 'Menu'
  	# has_many :menus, class_name: "Menu", foreign_key: "parent_id"

  	# Exemplo de policy fora da view/controller
  	# Pundit.policy(current_user, object).method?

	# validates_acceptance_of :accept_therm, accept: true, if: Proc.new { |user| user.profile_id == Profile::USER_ID && user.seed != true && user.seed != 'true' && user.skip_accept_therm.nil?}

	has_one_attached :profile_image

	# has_attached_file :profile_image,
	# :storage => :s3,
	# :url => ":s3_domain_url",
	# styles: { medium: "300x300#", thumb: "100x100#" },
	# :path => ":class/profile_image/:id_partition/:style/:filename"
	# do_not_validate_attachment_file_type :profile_image

	# validate :validate_age
	# validate :validate_cpf

	# Validações de e-mail
	validates_email_format_of :email, :message => I18n.t('model.invalid'), if: Proc.new { |user| user.seed != true && user.seed != 'true' && !user.email.blank? && user.skip_validate_password != true }

	# validates :email, 'valid_email_2/email': { mx: true }, if: Proc.new { |user| user.seed != true && user.seed != 'true' && !user.email.blank? && user.skip_validate_password != true}

	validates_uniqueness_of :email, :case_sensitive => false, if: Proc.new { |user| user.skip_validate_password != true }

	# Para situações de domínios customizados (arquivo whitelisted_email_domains.yml)
	# validates :email, 'valid_email_2/email': { disposable_domain_with_whitelist: true }, if: Proc.new { |user| user.seed != true && user.seed != 'true' && !user.email.blank?}

	# Criando usuário pelo retorno da autenticação social
	def self.find_or_create_from_auth_hash(auth)
		begin
			user = User.where(provider: auth.provider, uid: auth.uid).first
			if user.nil?
				user = User.find_by_email(auth.info.email)
				if user.nil?
					user = User.new
				end
			end
			if user.profile_id.nil?
				password = SecureRandom.urlsafe_base64
				user.profile_id = Profile::USER_ID
				user.password = password
				user.password_confirmation = password
			end
			user.provider = auth.provider
			user.uid = auth.uid
			user.name = auth.info.name
			user.email = auth.info.email
			user.skip_validate_password = true
			user.save
			return [user.valid?, user, user.errors.full_messages.join('<br>')]
		rescue Exception => e
			Rails.logger.error e.message
			return [false, nil, e.message]
		end
	end

	scope :active, -> { where(is_blocked: false) }

	scope :name_ordered, -> {
		order(Arel.sql("CASE WHEN users.person_type_id = 1 THEN users.name WHEN users.person_type_id = 2 THEN users.fantasy_name ELSE users.name END ASC"))
	}

	scope :admin, -> do
		where(profile_id: Profile::ADMIN_ID)
	end

	scope :user, -> do
		where(profile_id: Profile::USER_ID)
	end

	scope :client, -> do
		where(profile_id: Profile::CLIENT_ID)
	end

	scope :manager, -> do
		where(profile_id: Profile::MANAGER_ID)
	end

	scope :additional, -> do
		where(profile_id: Profile::ADDITIONAL_ID)
	end

	scope :provider, -> do
		where(profile_id: Profile::PROVIDER_ID)
	end

	scope :waiting_validation, -> do
		by_profiles_id([Profile::USER_ID])
    	.by_user_statuses_id([UserStatus::AGUARDANDO_AVALIACAO_ID, UserStatus::REPROVADO_ID])
	end

	scope :by_id, lambda { |value| where("users.id = ?", value) if !value.nil? && !value.blank? }

	scope :by_registration, lambda { |value| where("users.registration = ?", value) if !value.nil? && !value.blank? }

	scope :by_provider_state_ids, lambda { |value| joins(:address).where("addresses.state_id IN (?)", value) if !value.nil? && !value.blank? }

	scope :by_profile_id, lambda { |value| where(profile_id: value) if !value.nil? && !value.blank? }

	scope :by_provider_service_type_id, lambda { |value| joins(:provider_service_types).where("provider_service_types.id = ?", value) if !value.nil? && !value.blank? }

	scope :by_state_id, lambda { |value| where(state_id: value) if !value.nil? && !value.blank? }

	scope :by_city_id, lambda { |value| where(city_id: value) if !value.nil? && !value.blank? }

	scope :by_state_id_address, lambda { |value| joins(:address).where("addresses.state_id = ?", value) if !value.nil? && !value.blank? }

	scope :by_city_id_address, lambda { |value| joins(:address).where("addresses.city_id = ?", value) if !value.nil? && !value.blank? }

	scope :by_client_id, lambda { |value| where(client_id: value) if !value.nil? && !value.blank? }

	scope :by_profiles_id, lambda { |values| where(profile_id: [values]) if !values.nil? }

	scope :by_person_type_id, lambda { |value| where(person_type_id: value) if !value.nil? && !value.blank? }

	scope :by_user_status_id, lambda { |value| where(user_status_id: value) if !value.nil? && !value.blank? }

	scope :by_user_statuses_id, lambda { |values| where(user_status_id: [values]) if !values.nil? }

	scope :by_current_plan_id, lambda { |value| where("current_plan_id = ?", value) if !value.nil? && !value.blank? }

	scope :by_manually_plan_id, lambda { |value| where("manually_plan_id = ?", value) if !value.nil? && !value.blank? }

	scope :by_current_plans_id, lambda { |values| where("current_plan_id IN (?)", values) if !values.nil? }

	scope :by_civil_state_id, lambda { |value| where(civil_state_id: value) if !value.nil? && !value.blank? }

	scope :by_is_blocked, lambda { |value| where(is_blocked: value) if !value.nil? && !value.blank? }

	scope :by_name, lambda { |value| where("LOWER(users.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_social_name, lambda { |value| where("LOWER(users.social_name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_department, lambda { |value| where("LOWER(users.department) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_fantasy_name, lambda { |value| where("LOWER(users.fantasy_name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_all_name, lambda { |value| where("LOWER(users.name) LIKE ? OR LOWER(users.social_name) LIKE ? OR LOWER(users.fantasy_name) LIKE ?", "%#{value.downcase}%", "%#{value.downcase}%", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_email, lambda { |value| where("LOWER(users.email) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

	scope :by_cpf_cnpj, lambda { |value| where("users.cpf LIKE ? or users.cnpj LIKE ?", "%#{value}%", "%#{value}%") if !value.nil? && !value.blank? }

	scope :by_initial_date, lambda { |value| where("users.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
	scope :by_final_date, lambda { |value| where("users.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

	scope :by_initial_limit_date_manually_plan, lambda { |value| where("users.limit_date_manually_plan >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  	scope :by_final_limit_date_manually_plan, lambda { |value| where("users.limit_date_manually_plan <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }

	# Usuário é administrador?
	def admin?
		!profile.nil? && profile.admin?
	end

	# Usuário é usuário comum?
	def user?
		!profile.nil? && profile.user?
	end

	# Usuário é cliente?
	def client?
		!profile.nil? && profile.client?
	end

	# Usuário é gestor?
	def manager?
		!profile.nil? && profile.manager?
	end

	# Usuário é adicional?
	def additional?
		!profile.nil? && profile.additional?
	end

	# Usuário é fornecedor?
	def provider?
		!profile.nil? && profile.provider?
	end

	def discount_percent=(new_discount_percent)
		self[:discount_percent] = CustomHelper.currency_to_value(new_discount_percent)
	end

	def text_blocked
		if self.is_blocked
			return User.human_attribute_name(:set_active)
		end
		return User.human_attribute_name(:set_inactive)
	end

	def get_is_blocked?
		return (self.is_blocked ? User.human_attribute_name(:inactive) : User.human_attribute_name(:active))
	end

	def get_birthday
		return CustomHelper.get_text_date(self.birthday, 'date', :default)
	end

	def get_name
		if self.person_type_id == PersonType::FISICA_ID
			return self.name
		elsif self.person_type_id == PersonType::JURIDICA_ID
			return self.fantasy_name
		end
		return ''
	end

	def get_document
		if self.person_type_id == PersonType::FISICA_ID
			return CustomHelper.mask_cpf(self.cpf)
		elsif self.person_type_id == PersonType::JURIDICA_ID
			return self.cnpj
		end
		return ''
	end

	def get_first_phone
		result = nil
		if self.phones.length > 0
			result = self.phones.first
		end
		return result
	end

	def get_first_phone_phone
		result = ''
		phone = get_first_phone
		if !phone.nil? && !phone.phone.nil?
			result = phone.phone.gsub('.','')
			result = result.gsub(' ','')
			result = result.gsub('-','')
			result = result.gsub('/','')
		end
		return result
	end

	def get_profile_image
		result = "icons/profile-empty-new.webp"
		if self.profile_image.attached?
			result = Rails.application.routes.url_helpers.rails_blob_path(self.profile_image, only_path: true)
		end
		return result
	end

	def is_valid_to_buy?
		return (!self.name.nil? && !self.name.blank?) && (!self.cpf.nil? && !self.cpf.blank? && self.cpf.gsub(/[.,-]/, "").length > 0)
	end

	def get_document_clean
		if self.person_type_id == PersonType::FISICA_ID
			return clean_text(self.cpf)
		elsif self.person_type_id == PersonType::JURIDICA_ID
			return clean_text(self.cnpj)
		end
		return ''
	end

	def clean_text(text)
		result = text.gsub('.','')
		result = result.gsub(' ','')
		result = result.gsub('-','')
		result = result.gsub('/','')
		return result
	end

	def saving_profile_image_app
		if !self.profile_image_file.nil?
			self.profile_image.attach(
				io: StringIO.new(Base64.decode64(self.profile_image_file.split(',')[1])),
				content_type: 'image/jpeg',
				filename: 'profile_image.jpeg'
				)
		end
	end

	def get_state_city
		result = ""
		if !self.state.nil?
			result += self.state.acronym+"/"
		end
		if !self.city.nil?
			result += self.city.name
		end
		return result
	end

	def get_state_city_by_address
		result = ""
		if !self.address.nil? && !self.address.state.nil?
			result += self.address.state.acronym+" / "
		end
		if !self.address.nil? && !self.address.city.nil?
			result += self.address.city.name
		end
		return result
	end

	def get_address
		result = ""
		if !self.address.nil?
			result += self.address.address + ", "+ self.address.complement + ", " + self.address.number.to_s
		end
		return result
	end

	def get_city
		result = ""
		if !self.address.nil? && !self.address.city.nil?
			result += self.address.city.name
		end
		return result
	end

	def get_state
		result = ""
		if !self.address.nil? && !self.address.state.nil?
			result += self.address.state.name
		end
		return result
	end

	private

	def default_values
		self.name ||= ''
		self.cellphone ||= ''
		self.profession ||= ''
		self.registration ||= ''
		self.discount_percent ||= 0
		self.require_vehicle_photos = false if self.require_vehicle_photos.nil?

		self.person_type_id ||= PersonType::FISICA_ID
		self.sex_id ||= Sex::MASCULINO_ID
		self.user_status_id ||= UserStatus::AGUARDANDO_AVALIACAO_ID

		self.accept_therm ||= false if self.accept_therm.nil?
	end

	def validate_cpf
		require "cpf_cnpj"
		if !self.admin? && !CPF.valid?(self.cpf)
			errors.add(:cpf, I18n.t('model.invalid'))
		end
	end

	def insert_profile_image
		if !self.profile_image_url.nil? && !self.profile_image_url.blank?
			require 'uri'
			if self.profile_image_url =~ URI::regexp
				self.profile_image = URI.parse(self.profile_image_url).open
			end
		end
	end

	# def validate_cnpj
	# 	if !CNPJ.valid?(self.cnpj)
	# 		errors.add(:cnpj, "inválido")
	# 	end
	# end

	# Validando se o nome possui ao menos 2 palavras
	def name_is_less_than_2
		errors[:name] << "inválido" if name.split.size < 2
	end

	# Maior de 18 anos
	def validate_age
		if birthday.present? && birthday > 18.years.ago.to_date
			errors.add(:birthday, 'deve ser maior de 18 anos')
		end
	end

end
