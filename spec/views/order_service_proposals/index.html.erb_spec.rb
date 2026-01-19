require 'rails_helper'

RSpec.describe "order_service_proposals/index", type: :view do
  before(:each) do
    assign(:order_service_proposals, [
      OrderServiceProposal.create!(
        order_service: nil,
        provider: nil,
        order_service_proposal_status: nil,
        details: "MyText",
        total_value: "9.99",
        total_discount: "9.99",
        total_value_without_discount: "9.99"
      ),
      OrderServiceProposal.create!(
        order_service: nil,
        provider: nil,
        order_service_proposal_status: nil,
        details: "MyText",
        total_value: "9.99",
        total_discount: "9.99",
        total_value_without_discount: "9.99"
      )
    ])
  end

  it "renders a list of order_service_proposals" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
  end
end
