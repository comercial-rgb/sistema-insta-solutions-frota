require 'rails_helper'

RSpec.describe "cost_centers/index", type: :view do
  before(:each) do
    assign(:cost_centers, [
      CostCenter.create!(
        client: nil,
        name: "Name",
        contract_number: "Contract Number",
        commitment_number: "Commitment Number",
        initial_consumed_balance: "9.99",
        description: "MyText",
        budget_value: "9.99",
        budget_type: nil,
        has_sub_units: false
      ),
      CostCenter.create!(
        client: nil,
        name: "Name",
        contract_number: "Contract Number",
        commitment_number: "Commitment Number",
        initial_consumed_balance: "9.99",
        description: "MyText",
        budget_value: "9.99",
        budget_type: nil,
        has_sub_units: false
      )
    ])
  end

  it "renders a list of cost_centers" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Contract Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Commitment Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
