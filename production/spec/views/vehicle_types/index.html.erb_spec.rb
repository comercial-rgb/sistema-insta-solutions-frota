require 'rails_helper'

RSpec.describe "vehicle_types/index", type: :view do
  before(:each) do
    assign(:vehicle_types, [
      VehicleType.create!(
        name: "Name"
      ),
      VehicleType.create!(
        name: "Name"
      )
    ])
  end

  it "renders a list of vehicle_types" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
  end
end
