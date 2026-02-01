require 'rails_helper'

RSpec.describe "vehicle_types/edit", type: :view do
  let(:vehicle_type) {
    VehicleType.create!(
      name: "MyString"
    )
  }

  before(:each) do
    assign(:vehicle_type, vehicle_type)
  end

  it "renders the edit vehicle_type form" do
    render

    assert_select "form[action=?][method=?]", vehicle_type_path(vehicle_type), "post" do

      assert_select "input[name=?]", "vehicle_type[name]"
    end
  end
end
