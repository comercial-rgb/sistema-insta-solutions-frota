class OrderServiceSerializer < ActiveModel::Serializer
  attributes :id, :code, :km, :driver, :details
  has_one :order_service_status
  has_one :client
  has_one :vehicle
  has_one :provider_service_type
  has_one :maintenance_plan
  has_one :order_service_type
  has_one :provider

  attribute :created_at_formatted do
		CustomHelper.get_text_date(object.created_at, 'datetime', :full)
	end

	attribute :updated_at_formatted do
		CustomHelper.get_text_date(object.updated_at, 'datetime', :full)
	end

end
