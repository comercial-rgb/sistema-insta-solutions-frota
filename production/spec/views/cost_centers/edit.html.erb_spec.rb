require "rails_helper"

RSpec.describe "cost_centers/edit", type: :view do
  let(:cost_center) { create(:cost_center, :minimal, name: "Name", contract_number: "CN", commitment_number: "EM") }

  before(:each) do
    assign(:cost_center, cost_center)
  end

  it "renders the edit cost_center form" do
    expect { render }.not_to raise_error
  end
end
