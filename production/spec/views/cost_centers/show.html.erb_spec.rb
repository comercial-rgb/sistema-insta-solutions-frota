require 'rails_helper'

RSpec.describe "cost_centers/show", type: :view do
  before(:each) do
    assign(:cost_center, CostCenter.create!(
      client: nil,
      name: "Name",
      contract_number: "Contract Number",
      commitment_number: "Commitment Number",
      initial_consumed_balance: "9.99",
      description: "MyText",
      budget_value: "9.99",
      budget_type: nil,
      has_sub_units: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Contract Number/)
    expect(rendered).to match(/Commitment Number/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(//)
    expect(rendered).to match(/false/)
  end
end
