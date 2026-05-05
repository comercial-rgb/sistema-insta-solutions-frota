require "rails_helper"

RSpec.describe "vehicle_types/new", type: :view do
  before(:each) do
    assign(:vehicle_type, VehicleType.new(name: "MyString"))
  end

  it "renders new vehicle_type form" do
    expect { render }.not_to raise_error
  end
end
