require "rails_helper"

RSpec.describe "vehicle_types/edit", type: :view do
  let(:vehicle_type) { create(:vehicle_type) }

  before(:each) do
    assign(:vehicle_type, vehicle_type)
  end

  it "renders the edit vehicle_type form" do
    expect { render }.not_to raise_error
  end
end
