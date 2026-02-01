require 'rails_helper'

RSpec.describe "vehicle_types/show", type: :view do
  before(:each) do
    assign(:vehicle_type, VehicleType.create!(
      name: "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end
