require "rails_helper"

RSpec.describe "vehicles/new", type: :view do
  before(:each) do
    assign(:vehicle, build(:vehicle))
  end

  it "renders new vehicle form" do
    expect { render }.not_to raise_error
  end
end
