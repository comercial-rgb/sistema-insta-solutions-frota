class ServiceGroup < ApplicationRecord
  audited
  
  after_initialize :default_values

  # Validations
  validates :name, presence: true

  # Associations
  has_many :order_services, dependent: :restrict_with_error
  has_many :service_group_items, dependent: :destroy
  has_many :services, through: :service_group_items
  
  # Associação com clientes (filtro de acesso)
  has_many :service_group_clients, dependent: :destroy
  has_many :clients, through: :service_group_clients, class_name: 'User', source: :client
  
  accepts_nested_attributes_for :service_group_items, allow_destroy: true, reject_if: :all_blank

  # Scopes
  default_scope {
    order(:name)
  }

  scope :active, -> { where(active: true) }
  scope :by_id, lambda { |value| where("service_groups.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_name, lambda { |value| where("LOWER(service_groups.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_active, lambda { |value| where("service_groups.active = ?", value) if !value.nil? && !value.blank? }
  scope :by_initial_date, lambda { |value| where("service_groups.created_at >= ?", "#{value} 00:00:00") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("service_groups.created_at <= ?", "#{value} 23:59:59") if !value.nil? && !value.blank? }
  
  # Filtro por cliente: retorna grupos que o cliente pode utilizar
  # Se o grupo não tem clientes associados, está disponível para todos
  # Se tem clientes, só retorna se o client_id estiver na lista
  scope :available_for_client, lambda { |client_id|
    left_joins(:service_group_clients)
      .where('service_group_clients.id IS NULL OR service_group_clients.client_id = ?', client_id)
      .distinct
  }
  
  # Filtrar grupos disponíveis para um cliente específico
  # Se o grupo não tem clientes associados, está disponível para todos
  # Se tem clientes, só está disponível para os clientes especificados
  scope :available_for_client, lambda { |client_id| 
    if !client_id.nil? && !client_id.blank?
      left_joins(:service_group_clients)
        .where("service_group_clients.client_id = ? OR service_group_clients.id IS NULL", client_id)
        .distinct
    end
  }

  def get_text_name
    self.name
  end

  private

  def default_values
    self.active = true if self.active.nil?
  end

end
