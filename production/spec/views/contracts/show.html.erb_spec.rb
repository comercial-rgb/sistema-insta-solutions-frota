require 'rails_helper'

RSpec.describe "contracts/show", type: :view do
  before(:each) do
    assign(:contract, Contract.create!(
      client: nil,
      name: "Name",
      number: "Number",
      total_value: "9.99",
      active: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Number/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/false/)
  end
end
