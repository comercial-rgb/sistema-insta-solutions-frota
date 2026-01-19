class Vehicle < ApplicationRecord
  after_initialize :default_values

  default_scope {
    includes(:client, :cost_center, :vehicle_type)
    .order("vehicles.board")
  }

  scope :by_id, lambda { |value| where("vehicles.id = ?", value) if !value.nil? && !value.blank? }
  scope :by_client_id, lambda { |value| where("vehicles.client_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_cost_center_ids, lambda { |value| joins(:vehicle).where("vehicles.cost_center_id IN (?)", value) if !value.nil? && !value.blank? }
  scope :by_client_ids, lambda { |value| where("vehicles.client_id IN (?)", value) if !value.nil? && !value.blank? }
  scope :by_cost_center_id, lambda { |value| where("vehicles.cost_center_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_sub_unit_id, lambda { |value| where("vehicles.sub_unit_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_category_id, lambda { |value| where("vehicles.category_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_state_id, lambda { |value| where("vehicles.state_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_city_id, lambda { |value| where("vehicles.city_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_fuel_type_id, lambda { |value| where("vehicles.fuel_type_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_vehicle_type_id, lambda { |value| where("vehicles.vehicle_type_id = ?", value) if !value.nil? && !value.blank? }
  scope :by_active, lambda { |value| where("vehicles.active = ?", value) if !value.nil? && !value.blank? }
  scope :by_board, lambda { |value| where("LOWER(vehicles.board) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_brand, lambda { |value| where("LOWER(vehicles.brand) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_model, lambda { |value| where("LOWER(vehicles.model) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }
  scope :by_year, lambda { |value| where("vehicles.year = ?", value) if !value.nil? && !value.blank? }

  # scope :by_name, lambda { |value| where("LOWER(vehicles.name) LIKE ?", "%#{value.downcase}%") if !value.nil? && !value.blank? }

  scope :by_initial_acquisition_date, lambda { |value| where("vehicles.acquisition_date >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_acquisition_date, lambda { |value| where("vehicles.acquisition_date <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  scope :by_initial_maintenance_value, lambda { |value| where("vehicles.id > 0") if !value.nil? && !value.blank? }
  scope :by_final_maintenance_value, lambda { |value| where("vehicles.id > 0") if !value.nil? && !value.blank? }

  scope :by_initial_date, lambda { |value| where("vehicles.created_at >= '#{value} 00:00:00'") if !value.nil? && !value.blank? }
  scope :by_final_date, lambda { |value| where("vehicles.created_at <= '#{value} 23:59:59'") if !value.nil? && !value.blank? }

  scope :by_cost_center_or_sub_unit_ids, lambda { |cost_center_ids, sub_unit_ids|
    if cost_center_ids.present? || sub_unit_ids.present?
      where(
        arel_table[:cost_center_id].in(Array(cost_center_ids)).
        or(arel_table[:sub_unit_id].in(Array(sub_unit_ids)))
      )
    end
  }

  belongs_to :client, :class_name => 'User', optional: true
  belongs_to :cost_center, optional: true
  belongs_to :sub_unit, optional: true
  belongs_to :vehicle_type, optional: true
  belongs_to :category, optional: true
  belongs_to :state, optional: true
  belongs_to :city, optional: true
  belongs_to :fuel_type, optional: true

  has_many :order_services, validate: false, dependent: :destroy

  validates_presence_of :client_id, :cost_center_id, :fuel_type_id

  validates_presence_of :board

  validates_uniqueness_of :board, :scope => [:client_id]

  def get_text_name
    self.board.to_s
  end

  def market_value=(new_market_value)
		self[:market_value] = CustomHelper.currency_to_value(new_market_value)
	end

  def getting_cost_center_unit_name
    result = ""
    if !self.cost_center.nil?
      result += self.cost_center.name+'/'
    end
    if !self.sub_unit.nil?
      result += " "+self.sub_unit.name
    end
    return result
  end

  def get_maintenance_value
    return CustomHelper.to_currency(self.get_total_paid_value)
  end

  def self.getting_data_by_user(current_user)
    if current_user.manager? || current_user.additional?
      client_id = current_user.client_id
      cost_center_ids = current_user.associated_cost_centers.map(&:id)
      sub_unit_ids = current_user.associated_sub_units.map(&:id)
    end
    result = []
    if current_user.admin?
      result = Vehicle.by_active(true).order('vehicles.board').uniq
    elsif current_user.client?
      result = Vehicle.by_active(true).by_client_id(current_user.id).order('vehicles.board').uniq
    elsif current_user.manager?
      # Gerente vê apenas veículos do seu cliente e dos seus CCs/SUs
      result = Vehicle.by_active(true)
                      .by_client_id(client_id)
                      .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                      .order('vehicles.board').uniq
    elsif current_user.additional?
      # Adicional vê apenas veículos do seu cliente e dos seus CCs/SUs
      result = Vehicle.by_active(true)
                      .by_client_id(client_id)
                      .by_cost_center_or_sub_unit_ids(cost_center_ids, sub_unit_ids)
                      .order('vehicles.board').uniq
    end
    return result
  end

  def getting_vehicle_data
    result = ''
    result += self.brand + ", "
    result += self.model + ", "
    result += self.board + ", "
    result += self.year + ", "
    result += self.color
    return result
  end

  def getting_vehicle_data_custom
    result = ''
    result += self.board + ", "
    result += self.brand + " / "
    result += self.model
    return result
  end

  def get_total_paid_value
    result = 0
    invoiced_order_services = self.order_services.select{|item| [OrderServiceStatus::AUTORIZADA_ID, OrderServiceStatus::AGUARDANDO_PAGAMENTO_ID, OrderServiceStatus::PAGA_ID].include?(item.order_service_status_id)}
    invoiced_order_services.each do |order_service|
      order_service_proposal = order_service.order_service_proposals.select{|item| [OrderServiceProposalStatus::AUTORIZADA_ID, OrderServiceProposalStatus::AGUARDANDO_PAGAMENTO_ID, OrderServiceProposalStatus::PAGA_ID].include?(item.order_service_proposal_status_id)}.last
      if order_service_proposal
        result += order_service_proposal.total_value
      end
    end
    return result
  end

  def getting_last_km
    result = 0
    last_order_service = OrderService
      .unscoped
      .where(vehicle_id: self.id)
      .where.not(km: nil)
      .where.not(order_service_status_id: OrderServiceStatus::CANCELADA_ID)
      .order(created_at: :desc)
      .first
    if !last_order_service.nil?
      result = last_order_service.km
    end
    return result
  end

  private

  def default_values
    self.board ||= ""
    self.brand ||= ""
    self.model ||= ""
    self.year ||= ""
    self.color ||= ""
    self.renavam ||= ""
    self.chassi ||= ""
  end

end
