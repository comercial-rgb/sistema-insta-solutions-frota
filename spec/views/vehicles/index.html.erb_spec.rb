require 'rails_helper'

RSpec.describe "vehicles/index", type: :view do
  before(:each) do
    assign(:vehicles, [
      Vehicle.create!(
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
      ),
      Vehicle.create!(
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
      )
    ])
  end

  it "renders a list of vehicles" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Board".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Brand".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Model".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Year".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Color".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Renavam".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Chassi".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
