require 'rails_helper'

RSpec.describe "vehicle_types/new", type: :view do
  before(:each) do
    assign(:vehicle_type, VehicleType.new(
      name: "MyString"
    ))
  end

  it "renders new vehicle_type form" do
    render

    assert_select "form[action=?][method=?]", vehicle_types_path, "post" do

      assert_select "input[name=?]", "vehicle_type[name]"
    end
  end
end
