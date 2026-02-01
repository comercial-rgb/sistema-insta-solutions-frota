require 'rails_helper'

RSpec.describe "order_service_proposals/show", type: :view do
  before(:each) do
    assign(:order_service_proposal, OrderServiceProposal.create!(
      order_service: nil,
      provider: nil,
      order_service_proposal_status: nil,
      details: "MyText",
      total_value: "9.99",
      total_discount: "9.99",
      total_value_without_discount: "9.99"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
  end
end
