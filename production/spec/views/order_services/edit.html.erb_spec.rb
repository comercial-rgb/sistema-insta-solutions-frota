require 'rails_helper'

RSpec.describe "order_services/edit", type: :view do
  let(:order_service) {
    OrderService.create!(
      order_service_status: nil,
      client: nil,
      vehicle: nil,
      provider_service_type: nil,
      maintenance_plan: nil,
      order_service_type: nil,
      provider: nil,
      km: "MyString",
      driver: "MyString",
      details: "MyText"
    )
  }

  before(:each) do
    assign(:order_service, order_service)
  end

  it "renders the edit order_service form" do
    render

    assert_select "form[action=?][method=?]", order_service_path(order_service), "post" do

      assert_select "input[name=?]", "order_service[order_service_status_id]"

      assert_select "input[name=?]", "order_service[client_id]"

      assert_select "input[name=?]", "order_service[vehicle_id]"

      assert_select "input[name=?]", "order_service[provider_service_type_id]"

      assert_select "input[name=?]", "order_service[maintenance_plan_id]"

      assert_select "input[name=?]", "order_service[order_service_type_id]"

      assert_select "input[name=?]", "order_service[provider_id]"

      assert_select "input[name=?]", "order_service[km]"

      assert_select "input[name=?]", "order_service[driver]"

      assert_select "textarea[name=?]", "order_service[details]"
    end
  end
end
