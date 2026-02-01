require 'rails_helper'

RSpec.describe "order_services/show", type: :view do
  before(:each) do
    assign(:order_service, OrderService.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Km/)
    expect(rendered).to match(/Driver/)
    expect(rendered).to match(/MyText/)
  end
end
