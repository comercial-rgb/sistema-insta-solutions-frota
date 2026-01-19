require 'rails_helper'

RSpec.describe "order_service_proposals/new", type: :view do
  before(:each) do
    assign(:order_service_proposal, OrderServiceProposal.new(
      order_service: nil,
      provider: nil,
      order_service_proposal_status: nil,
      details: "MyText",
      total_value: "9.99",
      total_discount: "9.99",
      total_value_without_discount: "9.99"
    ))
  end

  it "renders new order_service_proposal form" do
    render

    assert_select "form[action=?][method=?]", order_service_proposals_path, "post" do

      assert_select "input[name=?]", "order_service_proposal[order_service_id]"

      assert_select "input[name=?]", "order_service_proposal[provider_id]"

      assert_select "input[name=?]", "order_service_proposal[order_service_proposal_status_id]"

      assert_select "textarea[name=?]", "order_service_proposal[details]"

      assert_select "input[name=?]", "order_service_proposal[total_value]"

      assert_select "input[name=?]", "order_service_proposal[total_discount]"

      assert_select "input[name=?]", "order_service_proposal[total_value_without_discount]"
    end
  end
end
