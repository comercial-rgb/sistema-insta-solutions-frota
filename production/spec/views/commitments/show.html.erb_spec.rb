require 'rails_helper'

RSpec.describe "commitments/show", type: :view do
  before(:each) do
    assign(:commitment, Commitment.create!(
      client: nil,
      cost_center: nil,
      contract: nil,
      commitment_number: "Commitment Number",
      commitment_value: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Commitment Number/)
    expect(rendered).to match(/9.99/)
  end
end
