require 'rails_helper'

RSpec.describe "vehicles/edit", type: :view do
  let(:vehicle) {
    Vehicle.create!(
      client: nil,
      cost_center: nil,
      sub_unit: nil,
      board: "MyString",
      brand: "MyString",
      model: "MyString",
      year: "MyString",
      color: "MyString",
      renavam: "MyString",
      chassi: "MyString",
      market_value: "9.99",
      vehicle_type: nil,
      category: nil,
      state: nil,
      city: nil,
      fuel_type: nil,
      active: false
    )
  }

  before(:each) do
    assign(:vehicle, vehicle)
  end

  it "renders the edit vehicle form" do
    render

    assert_select "form[action=?][method=?]", vehicle_path(vehicle), "post" do

      assert_select "input[name=?]", "vehicle[client_id]"

      assert_select "input[name=?]", "vehicle[cost_center_id]"

      assert_select "input[name=?]", "vehicle[sub_unit_id]"

      assert_select "input[name=?]", "vehicle[board]"

      assert_select "input[name=?]", "vehicle[brand]"

      assert_select "input[name=?]", "vehicle[model]"

      assert_select "input[name=?]", "vehicle[year]"

      assert_select "input[name=?]", "vehicle[color]"

      assert_select "input[name=?]", "vehicle[renavam]"

      assert_select "input[name=?]", "vehicle[chassi]"

      assert_select "input[name=?]", "vehicle[market_value]"

      assert_select "input[name=?]", "vehicle[vehicle_type_id]"

      assert_select "input[name=?]", "vehicle[category_id]"

      assert_select "input[name=?]", "vehicle[state_id]"

      assert_select "input[name=?]", "vehicle[city_id]"

      assert_select "input[name=?]", "vehicle[fuel_type_id]"

      assert_select "input[name=?]", "vehicle[active]"
    end
  end
end
