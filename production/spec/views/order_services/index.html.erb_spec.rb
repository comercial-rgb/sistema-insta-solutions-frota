require 'rails_helper'

RSpec.describe "order_services/index", type: :view do
  before(:each) do
    assign(:order_services, [
      OrderService.create!(
        order_service_status: nil,
        client: nil,
        vehicle: nil,
        provider_service_type: nil,
        maintenance_plan: nil,
        order_service_type: nil,
        provider: nil,
        km: "Km",
        driver: "Driver",
        details: "MyText"
      ),
      OrderService.create!(
        order_service_status: nil,
        client: nil,
        vehicle: nil,
        provider_service_type: nil,
        maintenance_plan: nil,
        order_service_type: nil,
        provider: nil,
        km: "Km",
        driver: "Driver",
        details: "MyText"
      )
    ])
  end

  it "renders a list of order_services" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Km".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Driver".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
