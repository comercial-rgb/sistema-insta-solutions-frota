require "rails_helper"

RSpec.describe "vehicle_types/show", type: :view do
  before(:each) do
    assign(:vehicle_type, create(:vehicle_type, name: "Name"))
  end

  it "renders attributes in <p>" do
    skip "No vehicle_types/show template in app/views"
  end
end
