require 'rails_helper'

RSpec.describe "vehicles/show", type: :view do
  before(:each) do
    assign(:vehicle, Vehicle.create!(
      client: nil,
      cost_center: nil,
      sub_unit: nil,
      board: "Board",
      brand: "Brand",
      model: "Model",
      year: "Year",
      color: "Color",
      renavam: "Renavam",
      chassi: "Chassi",
      market_value: "9.99",
      vehicle_type: nil,
      category: nil,
      state: nil,
      city: nil,
      fuel_type: nil,
      active: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Board/)
    expect(rendered).to match(/Brand/)
    expect(rendered).to match(/Model/)
    expect(rendered).to match(/Year/)
    expect(rendered).to match(/Color/)
    expect(rendered).to match(/Renavam/)
    expect(rendered).to match(/Chassi/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/false/)
  end
end
